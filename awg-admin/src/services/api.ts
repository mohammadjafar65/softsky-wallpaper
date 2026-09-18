import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'https://softskyapi.softsky.studio/api';

const api = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

type ApiPayload = Record<string, unknown>;
type PackListParams = {
    page?: number;
    limit?: number;
    search?: string;
    isPro?: boolean;
    isActive?: boolean;
};

export type AppSettings = {
    appName: string;
    supportEmail: string;
    contactEmail: string;
    privacyPolicyUrl: string;
    termsUrl: string;
    androidPackageName: string;
    minAppVersion: string;
    latestAppVersion: string;
    forceUpdate: boolean;
    maintenanceMode: boolean;
    maintenanceMessage: string;
    freeDownloadLimitPerDay: number;
    proDownloadLimitPerDay: number;
    enableNotifications: boolean;
    enableSubscriptions: boolean;
    enableWideWallpapers: boolean;
    defaultNotificationTitle: string;
    defaultNotificationMessage: string;
    enableLimitedTimeDeal: boolean;
    dealDiscountPercentage: number;
    dealOriginalPrice: number;
    dealDiscountedPrice: number;
    dealIntervalDays: number;
    dealTargetPlan: string;
    updatedAt?: string;
};

// Add auth token to requests
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle 401 Unauthorized: clear token and redirect to login
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            // Avoid redirect loop on login page
            if (!window.location.pathname.includes('/login')) {
                window.location.href = '/login';
            }
        }
        return Promise.reject(error);
    }
);


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
    update: (id: string, data: ApiPayload) => api.put(`/wallpapers/${id}`, data),
    bulkReassign: (data: { wallpaperIds: Array<string | number>; targetCategoryId: string | number }) =>
        api.put('/wallpapers/bulk-reassign', data),
    delete: (id: string) => api.delete(`/wallpapers/${id}`),
};

// Categories API
export const categoriesApi = {
    getAll: () => api.get('/categories'),
    create: (data: { name: string; icon?: string; description?: string }) =>
        api.post('/categories', data),
    update: (id: string, data: ApiPayload) => api.put(`/categories/${id}`, data),
    delete: (id: string) => api.delete(`/categories/${id}`),
    importPinterest: (boardUrl: string) => api.post('/categories/import-pinterest', { boardUrl }),
    refetchPinterest: (id: string) => api.post(`/categories/${id}/refetch-pinterest`),
};

// Users API
export const usersApi = {
    getAll: (params?: { page?: number; limit?: number; search?: string; plan?: string; role?: string; isCreator?: string }) =>
        api.get('/users', { params }),
    getById: (id: string) => api.get(`/users/${id}`),
    update: (id: string, data: ApiPayload) => api.put(`/users/${id}`, data),
    delete: (id: string) => api.delete(`/users/${id}`),
    getStats: () => api.get('/users/stats/overview'),
};

// Packs API
export const packsApi = {
    getAll: (params?: PackListParams) => api.get('/packs', { params }),
    getById: (id: string) => api.get(`/packs/${id}`),
    create: (data: FormData) => api.post('/packs', data, {
        headers: {
            'Content-Type': 'multipart/form-data',
        },
    }),
    update: (id: string, data: ApiPayload) => api.put(`/packs/${id}`, data),
    delete: (id: string) => api.delete(`/packs/${id}`),
};

export type NotificationTemplate = {
    id: number;
    name: string;
    title: string;
    message: string;
    imageUrl?: string | null;
    category?: string;
    isPremade?: boolean;
    createdAt?: string;
    updatedAt?: string;
};

// Notifications API
export const notificationsApi = {
    getStatus: () => api.get('/notifications/status'),
    sendToUser: (data: { userId: string; title: string; message: string; imageUrl?: string; data?: Record<string, string> }) =>
        api.post('/notifications/send-to-user', data),
    sendToAll: (data: { title: string; message: string; imageUrl?: string; data?: Record<string, string> }) =>
        api.post('/notifications/send-to-all', data),
    sendTest: (data: { token: string; title: string; message: string; imageUrl?: string; data?: Record<string, string> }) =>
        api.post('/notifications/test', data),
    uploadImage: (file: File) => {
        const formData = new FormData();
        formData.append('image', file);
        return api.post<{ success: boolean; url: string; thumbnailUrl: string }>('/notifications/upload-image', formData, {
            headers: { 'Content-Type': 'multipart/form-data' },
        });
    },
    getTemplates: () =>
        api.get<{ success: boolean; templates: NotificationTemplate[] }>('/notifications/templates'),
    createTemplate: (data: { name: string; title: string; message: string; imageUrl?: string; category?: string }) =>
        api.post<{ success: boolean; template: NotificationTemplate }>('/notifications/templates', data),
    deleteTemplate: (id: number) =>
        api.delete<{ success: boolean; message: string }>(`/notifications/templates/${id}`),
};

// Subscriptions API
export const subscriptionsApi = {
    getStats: () => api.get('/subscriptions/stats'),
    getSubscribers: (params?: { limit?: number }) => api.get('/subscriptions/subscribers', { params }),
};

export const healthApi = {
    get: () => api.get('/health'),
};

export const settingsApi = {
    get: () => api.get('/settings'),
    update: (data: Partial<AppSettings>) => api.put('/settings', data),
    getPublic: () => api.get('/settings/public'),
};

// Community API
export const communityApi = {
    getStats: () => api.get('/community/admin/stats'),
    getPosts: (params?: { page?: number; limit?: number; search?: string; filter?: string }) =>
        api.get('/community/admin/posts', { params }),
    deletePost: (id: number | string) => api.delete(`/community/admin/posts/${id}`),
    toggleApprove: (id: number | string) => api.patch(`/community/admin/posts/${id}/toggle-approve`),
    approvePost: (id: number | string) => api.patch(`/community/admin/posts/${id}/approve`),
    rejectPost: (id: number | string) => api.patch(`/community/admin/posts/${id}/reject`),
    getReports: () => api.get('/community/admin/reports'),
    dismissReport: (id: number | string) => api.delete(`/community/admin/reports/${id}`),
};

export default api;
