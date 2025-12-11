import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

const api = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Wallpapers API
export const wallpapersApi = {
    getAll: (params?: { page?: number; limit?: number; category?: string }) =>
        api.get('/wallpapers', { params }),
    getById: (id: string) => api.get(`/wallpapers/${id}`),
    search: (query: string) => api.get('/wallpapers/search', { params: { q: query } }),
    create: (formData: FormData) =>
        api.post('/wallpapers', formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        }),
    update: (id: string, data: any) => api.put(`/wallpapers/${id}`, data),
    delete: (id: string) => api.delete(`/wallpapers/${id}`),
};

// Categories API
export const categoriesApi = {
    getAll: () => api.get('/categories'),
    create: (data: { name: string; icon?: string; description?: string }) =>
        api.post('/categories', data),
    update: (id: string, data: any) => api.put(`/categories/${id}`, data),
    delete: (id: string) => api.delete(`/categories/${id}`),
};

// Users API
export const usersApi = {
    getAll: (params?: { page?: number; limit?: number; search?: string; plan?: string }) =>
        api.get('/users', { params }),
    getById: (id: string) => api.get(`/users/${id}`),
    update: (id: string, data: any) => api.put(`/users/${id}`, data),
    delete: (id: string) => api.delete(`/users/${id}`),
    getStats: () => api.get('/users/stats/overview'),
};

// Packs API
export const packsApi = {
    getAll: (params?: any) => api.get('/packs', { params }),
    getById: (id: string) => api.get(`/packs/${id}`),
    create: (data: FormData) => api.post('/packs', data, {
        headers: {
            'Content-Type': 'multipart/form-data',
        },
    }),
    update: (id: string, data: any) => api.put(`/packs/${id}`, data),
    delete: (id: string) => api.delete(`/packs/${id}`),
};

// Subscriptions API
export const subscriptionsApi = {
    getStats: () => usersApi.getStats(),
};

export default api;
