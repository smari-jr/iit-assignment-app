import React, { createContext, useContext, useReducer, useEffect } from 'react';
import api from '../services/api';

// Initial state
const initialState = {
  products: [],
  cart: [],
  loading: false,
  error: null,
  user: null
};

// Action types
const actionTypes = {
  SET_LOADING: 'SET_LOADING',
  SET_PRODUCTS: 'SET_PRODUCTS',
  SET_ERROR: 'SET_ERROR',
  ADD_TO_CART: 'ADD_TO_CART',
  REMOVE_FROM_CART: 'REMOVE_FROM_CART',
  UPDATE_CART_QUANTITY: 'UPDATE_CART_QUANTITY',
  CLEAR_CART: 'CLEAR_CART',
  SET_USER: 'SET_USER',
  ADD_PRODUCT: 'ADD_PRODUCT'
};

// Reducer function
const gamingReducer = (state, action) => {
  switch (action.type) {
    case actionTypes.SET_LOADING:
      return { ...state, loading: action.payload };
    case actionTypes.SET_PRODUCTS:
      return { ...state, products: action.payload, loading: false };
    case actionTypes.SET_ERROR:
      return { ...state, error: action.payload, loading: false };
      return { ...state, error: action.payload, loading: false };
    case actionTypes.ADD_TO_CART:
      return { ...state, cart: [...state.cart, action.payload] };
    case actionTypes.REMOVE_FROM_CART:
      return { ...state, cart: state.cart.filter(item => item.id !== action.payload) };
    case actionTypes.UPDATE_CART_QUANTITY:
      return {
        ...state,
        cart: state.cart.map(item =>
          item.id === action.payload.id
            ? { ...item, quantity: action.payload.quantity }
            : item
        )
      };
    case actionTypes.CLEAR_CART:
      return { ...state, cart: [] };
    case actionTypes.SET_USER:
      return { ...state, user: action.payload };
    case actionTypes.ADD_PRODUCT:
      return { ...state, products: [...state.products, action.payload] };
    default:
      return state;
  }
};

// Create context
const GamingContext = createContext();

// Provider component
export const GamingProvider = ({ children }) => {
  const [state, dispatch] = useReducer(gamingReducer, initialState);

  // Load products
  const loadProducts = async () => {
    dispatch({ type: actionTypes.SET_LOADING, payload: true });
    try {
      const response = await api.gaming.getProducts();
      
      if (response && response.success && response.data) {
        dispatch({ type: actionTypes.SET_PRODUCTS, payload: response.data });
      } else {
        dispatch({ type: actionTypes.SET_ERROR, payload: 'Invalid response format' });
      }
    } catch (error) {
      dispatch({ type: actionTypes.SET_ERROR, payload: error.message });
    }
  };

  // Create product
  const createProduct = async (productData) => {
    try {
      const response = await api.gaming.createProduct(productData);
      if (response && response.success && response.data) {
        dispatch({ type: actionTypes.ADD_PRODUCT, payload: response.data });
        return response.data;
      }
    } catch (error) {
      console.error('Error creating product:', error);
      dispatch({ type: actionTypes.SET_ERROR, payload: error.message });
      throw error;
    }
  };

  // Add to cart
  const addToCart = (product) => {
    const existingItem = state.cart.find(item => item.id === product.id);
    if (existingItem) {
      dispatch({
        type: actionTypes.UPDATE_CART_QUANTITY,
        payload: { id: product.id, quantity: existingItem.quantity + 1 }
      });
    } else {
      dispatch({ type: actionTypes.ADD_TO_CART, payload: { ...product, quantity: 1 } });
    }
  };

  // Remove from cart
  const removeFromCart = (productId) => {
    dispatch({ type: actionTypes.REMOVE_FROM_CART, payload: productId });
  };

  // Update cart quantity
  const updateCartQuantity = (productId, quantity) => {
    if (quantity <= 0) {
      removeFromCart(productId);
    } else {
      dispatch({ type: actionTypes.UPDATE_CART_QUANTITY, payload: { id: productId, quantity } });
    }
  };

  // Clear cart
  const clearCart = () => {
    dispatch({ type: actionTypes.CLEAR_CART });
  };

  // Load products on mount
  useEffect(() => {
    loadProducts();
  }, []);

  const value = {
    ...state,
    loadProducts,
    createProduct,
    addToCart,
    removeFromCart,
    updateCartQuantity,
    clearCart
  };

  return (
    <GamingContext.Provider value={value}>
      {children}
    </GamingContext.Provider>
  );
};

// Custom hook
export const useGaming = () => {
  const context = useContext(GamingContext);
  if (!context) {
    throw new Error('useGaming must be used within a GamingProvider');
  }
  return context;
};
