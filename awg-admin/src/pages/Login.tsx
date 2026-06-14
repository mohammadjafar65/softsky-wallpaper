import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';
import axios from 'axios';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setIsLoading(true);

    try {
      await login(email, password);
      toast.success('Welcome back');
      navigate('/');
    } catch (error: unknown) {
      const message = axios.isAxiosError<{ error?: string }>(error)
        ? error.response?.data?.error
        : undefined;
      toast.error(message || 'Login failed. Please check your credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="admin-login">
      <div className="admin-login__panel">
        <section className="admin-login__hero">
          <p className="admin-page__eyebrow">SoftSky Admin App</p>
          <h1>Manage wallpapers from a calmer, app-like workspace.</h1>
          <p className="admin-login__helper">
            Upload new collections, update premium flags, remove old content, and keep the wallpaper
            library in sync with your live server from one minimal control surface.
          </p>

          <div className="admin-login__hero-metrics">
            <div>
              <strong>Upload</strong>
              <span>Add wallpapers in batches</span>
            </div>
            <div>
              <strong>Manage</strong>
              <span>Edit, classify, and delete fast</span>
            </div>
            <div>
              <strong>Sync</strong>
              <span>Connected directly to backend APIs</span>
            </div>
          </div>
        </section>

        <section className="admin-login__form">
          <div>
            <p className="admin-page__eyebrow">Admin Access</p>
            <h2>Sign in</h2>
            <p className="admin-login__helper">Use your admin credentials to enter the panel.</p>
          </div>

          <div className="admin-panel">
            <form onSubmit={(e) => void handleSubmit(e)} className="admin-grid">
              <div className="afield">
                <label className="afield__label" htmlFor="email">Email address</label>
                <input id="email" type="email" className="afield__input" placeholder="name@company.com" value={email} onChange={(e) => setEmail(e.target.value)} required />
              </div>

              <div className="afield">
                <label className="afield__label" htmlFor="password">Password</label>
                <input id="password" type="password" className="afield__input" placeholder="Enter password" value={password} onChange={(e) => setPassword(e.target.value)} required />
              </div>

              <button type="submit" className="amodal-btn--primary" style={{ height: 42, marginTop: 4 }} disabled={isLoading}>
                {isLoading ? 'Signing in…' : 'Sign in'}
              </button>
            </form>
          </div>
        </section>
      </div>
    </div>
  );
}
