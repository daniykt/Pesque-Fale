BEGIN;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

CREATE FUNCTION public.atualizar_avg_nota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE pontos_de_pesca
  SET
    avg_nota = (
      SELECT ROUND(AVG(nota)::numeric, 1)
      FROM avaliacoes
      WHERE ponto_id = COALESCE(NEW.ponto_id, OLD.ponto_id)
    ),
    total_avaliacoes = (
      SELECT COUNT(*)
      FROM avaliacoes
      WHERE ponto_id = COALESCE(NEW.ponto_id, OLD.ponto_id)
    )
  WHERE id = COALESCE(NEW.ponto_id, OLD.ponto_id);
  RETURN NEW;
END;
$$;

CREATE TABLE public.usuarios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nome character varying(100) NOT NULL,
    username character varying(50),
    email character varying(255) NOT NULL,
    senha_hash character varying(255) NOT NULL,
    foto_perfil text,
    banner text,
    bio text DEFAULT ''::text,
    localizacao character varying(100) DEFAULT ''::character varying,
    onboarding_concluido boolean DEFAULT false,
    firebase_uid character varying(128),
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);

CREATE TABLE public.usuario_seguidores (
    seguidor_id uuid NOT NULL,
    seguido_id uuid NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);

CREATE TABLE public.pontos_de_pesca (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    cidade character varying(100) NOT NULL,
    estado character varying(2) NOT NULL,
    tipo character varying(50) NOT NULL,
    foto_capa text,
    fotos text[],
    tags text[],
    avg_nota numeric(2,1) DEFAULT 0,
    total_avaliacoes integer DEFAULT 0,
    criado_por uuid NOT NULL,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT pontos_de_pesca_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['pesqueiro'::character varying, 'rio'::character varying, 'lago'::character varying, 'represa'::character varying, 'mar'::character varying])::text[])))
);

CREATE TABLE public.avaliacoes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    usuario_id uuid NOT NULL,
    ponto_id uuid NOT NULL,
    nota numeric(2,1) NOT NULL,
    comentario text,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT avaliacoes_nota_check CHECK (((nota >= 1.0) AND (nota <= 5.0)))
);

CREATE TABLE public.publicacoes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    autor_id uuid NOT NULL,
    ponto_id uuid,
    descricao text,
    imagem_url text,
    local_texto character varying(100),
    avaliacao_nota numeric(2,1),
    curtidas_count integer DEFAULT 0,
    comentarios_count integer DEFAULT 0,
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);

CREATE TABLE public.eventos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    titulo character varying(200) NOT NULL,
    descricao text,
    ponto_id uuid,
    organizador_id uuid NOT NULL,
    data_inicio timestamp without time zone NOT NULL,
    data_fim timestamp without time zone,
    imagem_url text,
    local_texto character varying(150),
    criado_em timestamp without time zone DEFAULT now(),
    atualizado_em timestamp without time zone DEFAULT now()
);

CREATE TABLE public.chats (
    id character varying(255) NOT NULL,
    participante_a uuid NOT NULL,
    participante_b uuid NOT NULL,
    criado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT chats_check CHECK ((participante_a < participante_b))
);

CREATE TABLE public.mensagens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    chat_id character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    nome character varying(100) NOT NULL,
    texto text NOT NULL,
    status character varying(20) DEFAULT 'enviado'::character varying,
    criado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT mensagens_status_check CHECK (((status)::text = ANY ((ARRAY['enviado'::character varying, 'visto'::character varying])::text[])))
);

CREATE TABLE public.notificacoes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    para uuid NOT NULL,
    de_id uuid,
    de character varying(100),
    de_username character varying(50),
    tipo character varying(50) NOT NULL,
    texto text,
    post_id uuid,
    chat_id character varying(255),
    lida boolean DEFAULT false,
    criado_em timestamp without time zone DEFAULT now(),
    CONSTRAINT notificacoes_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['curtida'::character varying, 'comentario'::character varying, 'seguindo'::character varying, 'mensagem'::character varying, 'sistema'::character varying])::text[])))
);

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);
ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_username_key UNIQUE (username);

ALTER TABLE ONLY public.usuario_seguidores
    ADD CONSTRAINT usuario_seguidores_pkey PRIMARY KEY (seguidor_id, seguido_id);

ALTER TABLE ONLY public.pontos_de_pesca
    ADD CONSTRAINT pontos_de_pesca_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.avaliacoes
    ADD CONSTRAINT avaliacoes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.avaliacoes
    ADD CONSTRAINT avaliacoes_usuario_id_ponto_id_key UNIQUE (usuario_id, ponto_id);

ALTER TABLE ONLY public.publicacoes
    ADD CONSTRAINT publicacoes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_participante_a_participante_b_key UNIQUE (participante_a, participante_b);

ALTER TABLE ONLY public.mensagens
    ADD CONSTRAINT mensagens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notificacoes
    ADD CONSTRAINT notificacoes_pkey PRIMARY KEY (id);

CREATE INDEX pontos_de_pesca_st_makepoint_idx ON public.pontos_de_pesca USING gist (public.st_makepoint((longitude)::double precision, (latitude)::double precision));
CREATE INDEX publicacoes_autor_id_criado_em_idx ON public.publicacoes USING btree (autor_id, criado_em DESC);
CREATE INDEX eventos_data_inicio_idx ON public.eventos USING btree (data_inicio DESC);
CREATE INDEX eventos_organizador_id_data_inicio_idx ON public.eventos USING btree (organizador_id, data_inicio DESC);
CREATE INDEX mensagens_chat_id_criado_em_idx ON public.mensagens USING btree (chat_id, criado_em DESC);
CREATE INDEX notificacoes_para_criado_em_idx ON public.notificacoes USING btree (para, criado_em DESC);

CREATE TRIGGER trigger_avg_nota AFTER INSERT OR DELETE OR UPDATE ON public.avaliacoes FOR EACH ROW EXECUTE FUNCTION public.atualizar_avg_nota();

ALTER TABLE ONLY public.usuario_seguidores
    ADD CONSTRAINT usuario_seguidores_seguidor_id_fkey FOREIGN KEY (seguidor_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.usuario_seguidores
    ADD CONSTRAINT usuario_seguidores_seguido_id_fkey FOREIGN KEY (seguido_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pontos_de_pesca
    ADD CONSTRAINT pontos_de_pesca_criado_por_fkey FOREIGN KEY (criado_por) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.avaliacoes
    ADD CONSTRAINT avaliacoes_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.avaliacoes
    ADD CONSTRAINT avaliacoes_ponto_id_fkey FOREIGN KEY (ponto_id) REFERENCES public.pontos_de_pesca(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.publicacoes
    ADD CONSTRAINT publicacoes_autor_id_fkey FOREIGN KEY (autor_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.publicacoes
    ADD CONSTRAINT publicacoes_ponto_id_fkey FOREIGN KEY (ponto_id) REFERENCES public.pontos_de_pesca(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_organizador_id_fkey FOREIGN KEY (organizador_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_ponto_id_fkey FOREIGN KEY (ponto_id) REFERENCES public.pontos_de_pesca(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_participante_a_fkey FOREIGN KEY (participante_a) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.chats
    ADD CONSTRAINT chats_participante_b_fkey FOREIGN KEY (participante_b) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.mensagens
    ADD CONSTRAINT mensagens_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES public.chats(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.mensagens
    ADD CONSTRAINT mensagens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notificacoes
    ADD CONSTRAINT notificacoes_para_fkey FOREIGN KEY (para) REFERENCES public.usuarios(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.notificacoes
    ADD CONSTRAINT notificacoes_de_id_fkey FOREIGN KEY (de_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;

COMMIT;