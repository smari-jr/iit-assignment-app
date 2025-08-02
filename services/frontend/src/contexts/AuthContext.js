import React, { createContext, useContext, useReducer, useEffect } from 'react';
import api from '../services/api';
import analytics from '../services/analytics';

// Auth Context
const AuthContext = createContext();

const authReducer = (state, action) => {
  switch (action.type) {
    case 'LOGIN_START':
      return { ...state, loading: true, error: null };
    case 'LOGIN_SUCCESS':
      return { 
        ...state, 
        loading: false, 
        isAuthenticated: true, 
        user: action.payload.user,
        token: action.payload.token 
      };
    case 'LOGIN_FAILURE':
      return { 
        ...state, 
        loading: false, 
        error: action.payload, 
        isAuthenticated: false 
      };
    case 'LOGOUT':
      return { 
        ...state, 
        isAuthenticated: false, 
        user: null, 
        token: null 
      };
    case 'UPDATE_PROFILE':
      return { ...state, user: { ...state.user, ...action.payload } };
    default:
      return state;
  }
};

export const AuthProvider = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, {
    isAuthenticated: api.auth.isAuthenticated(),
    user: null,
    token: api.auth.getToken(),
    loading: false,
    error: null
  });

  useEffect(() => {
    if (state.token && !state.user) {
      // Load user profile if token exists but user data is missing
      loadUserProfile();
    }
  }, [state.token]);

  const loadUserProfile = async () => {
    try {
      const user = await api.gaming.getProfile();
      dispatch({ type: 'LOGIN_SUCCESS', payload: { user, token: state.token } });
    } catch (error) {
      console.error('Failed to load user profile:', error);
      logout();
    }
  };

  const login = async (credentials) => {
    dispatch({ type: 'LOGIN_START' });
    try {
      const response = await api.gaming.login(credentials);
      api.auth.setToken(response.token);
      dispatch({ 
        type: 'LOGIN_SUCCESS', 
        payload: { user: response.user, token: response.token } 
      });
      
      // Update analytics with user ID
      analytics.setUserId(response.user.id);
      analytics.trackCustomEvent('auth', 'login', {
        username: response.user.username,
        login_method: 'password'
      });
      
      return response;
    } catch (error) {
      dispatch({ type: 'LOGIN_FAILURE', payload: error.message });
      
      // Track login failure
      analytics.trackCustomEvent('auth', 'login_failed', {
        error: error.message,
        email: credentials.email
      });
      
      throw error;
    }
  };

  const register = async (userData) => {
    dispatch({ type: 'LOGIN_START' });
    try {
      const response = await api.gaming.register(userData);
      api.auth.setToken(response.token);
      dispatch({ 
        type: 'LOGIN_SUCCESS', 
        payload: { user: response.user, token: response.token } 
      });
      
      // Update analytics with user ID and track registration
      analytics.setUserId(response.user.id);
      analytics.trackCustomEvent('auth', 'register', {
        username: response.user.username,
        registration_method: 'email'
      });
      
      return response;
    } catch (error) {
      dispatch({ type: 'LOGIN_FAILURE', payload: error.message });
      
      // Track registration failure
      analytics.trackCustomEvent('auth', 'register_failed', {
        error: error.message,
        email: userData.email
      });
      
      throw error;
    }
  };

  const logout = async () => {
    try {
      // Track logout event before clearing data
      analytics.trackCustomEvent('auth', 'logout', {
        username: state.user?.username,
        session_duration: analytics.getSessionSummary().sessionDuration
      });
      
      await api.gaming.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      api.auth.removeToken();
      dispatch({ type: 'LOGOUT' });
      
      // Clear user ID from analytics
      analytics.setUserId(null);
    }
  };

  const updateProfile = async (userData) => {
    try {
      const updatedUser = await api.gaming.updateProfile(userData);
      dispatch({ type: 'UPDATE_PROFILE', payload: updatedUser });
      return updatedUser;
    } catch (error) {
      console.error('Profile update error:', error);
      throw error;
    }
  };

  return (
    <AuthContext.Provider value={{
      ...state,
      login,
      register,
      logout,
      updateProfile
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
