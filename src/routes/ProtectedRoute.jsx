import { Navigate } from "react-router-dom";

export default function ProtectedRoute({ user, loading, children }) {
  if (loading) return null;

  if (!user) {
    return <Navigate to="/login" />;
  }

  return children;
}