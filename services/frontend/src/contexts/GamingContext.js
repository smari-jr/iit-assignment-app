import React, { createContext, useContext, useReducer, useEffect } from 'react';
import api from '../services/api';

// Gaming Context for products and gaming-related data
const GamingContext = createContext();

const gamingReducer = (state, action) => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload, loading: false };
    case 'SET_PRODUCTS':
      return { ...state, products: action.payload, loading: false };
    case 'ADD_PRODUCT':
      return { 
        ...state, 
        products: [...state.products, action.payload], 
        loading: false 
      };
    case 'UPDATE_PRODUCT':
      return {
        ...state,
        products: state.products.map(product =>
          product.id === action.payload.id ? action.payload : product
        ),
        loading: false
      };
    case 'DELETE_PRODUCT':
      return {
        ...state,
        products: state.products.filter(product => product.id !== action.payload),
        loading: false
      };
    default:
      return state;
  }
};

export const GamingProvider = ({ children }) => {
  const [state, dispatch] = useReducer(gamingReducer, {
    products: [],
    loading: false,
    error: null
  });

  const loadProducts = async () => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const products = await api.gaming.getProducts();
      dispatch({ type: 'SET_PRODUCTS', payload: products });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
    }
  };

  const createProduct = async (productData) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const newProduct = await api.gaming.createProduct(productData);
      dispatch({ type: 'ADD_PRODUCT', payload: newProduct });
      return newProduct;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const updateProduct = async (id, productData) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const updatedProduct = await api.gaming.updateProduct(id, productData);
      dispatch({ type: 'UPDATE_PRODUCT', payload: updatedProduct });
      return updatedProduct;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const deleteProduct = async (id) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      await api.gaming.deleteProduct(id);
      dispatch({ type: 'DELETE_PRODUCT', payload: id });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  useEffect(() => {
    loadProducts();
  }, []);

  return (
    <GamingContext.Provider value={{
      ...state,
      loadProducts,
      createProduct,
      updateProduct,
      deleteProduct
    }}>
      {children}
    </GamingContext.Provider>
  );
};

export const useGaming = () => {
  const context = useContext(GamingContext);
  if (!context) {
    throw new Error('useGaming must be used within a GamingProvider');
  }
  return context;
};
