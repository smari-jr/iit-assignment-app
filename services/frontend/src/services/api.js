// API Configuration and Service Layer
const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || '';

// All requests should go through the frontend server (nginx proxy)
// Nginx will handle routing to the appropriate microservice
const SERVICES = {
  gaming: '', // Empty string means use same origin
  orders: '', 
  analytics: ''
};

// API endpoints configuration
const ENDPOINTS = {
  gaming: {
    products: '/api/products',
    auth: '/api/auth',
    users: '/api/users'
  },
  orders: {
    base: '/api/orders'
  },
  analytics: {
    dashboard: '/analytics/dashboard',
    pageVisits: '/analytics/page-visits'
  }
};

// Generic API request function
const apiRequest = async (url, options = {}, serviceUrl = null) => {
  const config = {
    headers: {
      'Content-Type': 'application/json',
      ...options.headers
    },
    ...options
  };

  // Add auth token if available
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  // Determine the full URL
  const baseUrl = serviceUrl || API_BASE_URL;
  const fullUrl = `${baseUrl}${url}`;

  try {
    const response = await fetch(fullUrl, config);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      return await response.json();
    }
    
    return await response.text();
  } catch (error) {
    console.error('API Request failed:', error);
    throw error;
  }
};

// Gaming Service API
export const gamingAPI = {
  // Products
  getProducts: () => apiRequest(ENDPOINTS.gaming.products, {}, SERVICES.gaming),
  getProduct: (id) => apiRequest(`${ENDPOINTS.gaming.products}/${id}`, {}, SERVICES.gaming),
  createProduct: (productData) => apiRequest(ENDPOINTS.gaming.products, {
    method: 'POST',
    body: JSON.stringify(productData)
  }, SERVICES.gaming),
  updateProduct: (id, productData) => apiRequest(`${ENDPOINTS.gaming.products}/${id}`, {
    method: 'PUT',
    body: JSON.stringify(productData)
  }, SERVICES.gaming),
  deleteProduct: (id) => apiRequest(`${ENDPOINTS.gaming.products}/${id}`, {
    method: 'DELETE'
  }, SERVICES.gaming),

  // Authentication
  login: (credentials) => apiRequest(`${ENDPOINTS.gaming.auth}/login`, {
    method: 'POST',
    body: JSON.stringify(credentials)
  }, SERVICES.gaming),
  register: (userData) => apiRequest(`${ENDPOINTS.gaming.auth}/register`, {
    method: 'POST',
    body: JSON.stringify(userData)
  }, SERVICES.gaming),
  logout: () => apiRequest(`${ENDPOINTS.gaming.auth}/logout`, {
    method: 'POST'
  }, SERVICES.gaming),

  // Users
  getProfile: () => apiRequest(ENDPOINTS.gaming.users, {}, SERVICES.gaming),
  updateProfile: (userData) => apiRequest(ENDPOINTS.gaming.users, {
    method: 'PUT',
    body: JSON.stringify(userData)
  }, SERVICES.gaming),
  getUserById: (id) => apiRequest(`${ENDPOINTS.gaming.users}/${id}`, {}, SERVICES.gaming)
};

// Order Service API
export const orderAPI = {
  getOrders: () => apiRequest(ENDPOINTS.orders.base, {}, SERVICES.orders),
  getOrder: (id) => apiRequest(`${ENDPOINTS.orders.base}/${id}`, {}, SERVICES.orders),
  createOrder: (orderData) => apiRequest(ENDPOINTS.orders.base, {
    method: 'POST',
    body: JSON.stringify(orderData)
  }, SERVICES.orders),
  updateOrder: (id, orderData) => apiRequest(`${ENDPOINTS.orders.base}/${id}`, {
    method: 'PUT',
    body: JSON.stringify(orderData)
  }, SERVICES.orders),
  cancelOrder: (id) => apiRequest(`${ENDPOINTS.orders.base}/${id}/cancel`, {
    method: 'POST'
  }, SERVICES.orders),
  getUserOrders: (userId) => apiRequest(`${ENDPOINTS.orders.base}/user/${userId}`, {}, SERVICES.orders)
};

// Analytics Service API
export const analyticsAPI = {
  getDashboard: () => apiRequest(ENDPOINTS.analytics.dashboard, {}, SERVICES.analytics),
  getPageVisits: (params = {}) => {
    const queryString = new URLSearchParams(params).toString();
    return apiRequest(`${ENDPOINTS.analytics.pageVisits}?${queryString}`, {}, SERVICES.analytics);
  },
  trackEvent: (eventData) => apiRequest('/analytics/track', {
    method: 'POST',
    body: JSON.stringify(eventData)
  }, SERVICES.analytics)
};

// Utility functions for token management
export const authUtils = {
  setToken: (token) => localStorage.setItem('authToken', token),
  getToken: () => localStorage.getItem('authToken'),
  removeToken: () => localStorage.removeItem('authToken'),
  isAuthenticated: () => !!localStorage.getItem('authToken')
};

export default {
  gaming: gamingAPI,
  orders: orderAPI,
  analytics: analyticsAPI,
  auth: authUtils
};
