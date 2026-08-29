const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Pesque & Fale API',
      version: '1.0.0',
      description: 'API REST do aplicativo Pesque & Fale — Fases 0 a 4',
    },
    servers: [
      { url: 'http://localhost:3333/v1', description: 'Desenvolvimento' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ['./src/modules/**/*.routes.js'],
};

module.exports = swaggerJsdoc(options);