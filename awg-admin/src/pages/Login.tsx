import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, PasswordInput, TextInput, Tile } from '@carbon/react';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

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
    } catch (error: any) {
      toast.error(error.response?.data?.error || 'Login failed. Please check your credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="admin-login">
      <div className="admin-login__panel">
        <section className="admin-login__hero">
          <p className="admin-page__eyebrow">Carbon Dark Mode</p>
          <h1>Operate SoftSky from a cleaner, system-first admin workspace.</h1>
          <p className="admin-login__helper">
            Review content velocity, manage premium inventory, and coordinate user operations from a
            Carbon-driven control room built for dense admin workflows.
          </p>

          <div className="admin-login__hero-metrics">
            <div>
              <strong>8</strong>
              <span>Core admin modules</span>
            </div>
            <div>
              <strong>1</strong>
              <span>Unified dark theme</span>
            </div>
            <div>
              <strong>24/7</strong>
              <span>Operational visibility</span>
            </div>
          </div>
        </section>

        <section className="admin-login__form">
          <div>
            <p className="admin-page__eyebrow">Admin Access</p>
            <h2>Sign in</h2>
            <p className="admin-login__helper">Use your admin credentials to enter the panel.</p>
          </div>

          <Tile className="admin-panel">
            <form onSubmit={handleSubmit} className="admin-grid">
              <TextInput
                id="email"
                labelText="Email address"
                placeholder="name@company.com"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
              />

              <PasswordInput
                id="password"
                labelText="Password"
                placeholder="Enter password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
              />

              <Button type="submit" disabled={isLoading}>
                {isLoading ? 'Signing in...' : 'Sign in'}
              </Button>
            </form>
          </Tile>
        </section>
      </div>
    </div>
  );
}
