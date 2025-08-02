import React, { createContext, useContext, useReducer } from 'react';
import api from '../services/api';
import { useAuth } from './AuthContext';

// Orders Context
const OrdersContext = createContext();

const ordersReducer = (state, action) => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload, loading: false };
    case 'SET_ORDERS':
      return { ...state, orders: action.payload, loading: false };
    case 'ADD_ORDER':
      return { 
        ...state, 
        orders: [action.payload, ...state.orders], 
        loading: false 
      };
    case 'UPDATE_ORDER':
      return {
        ...state,
        orders: state.orders.map(order =>
          order.id === action.payload.id ? action.payload : order
        ),
        loading: false
      };
    case 'SET_CART':
      return { ...state, cart: action.payload };
    case 'ADD_TO_CART':
      return {
        ...state,
        cart: [...state.cart, action.payload]
      };
    case 'REMOVE_FROM_CART':
      return {
        ...state,
        cart: state.cart.filter(item => item.id !== action.payload)
      };
    case 'CLEAR_CART':
      return { ...state, cart: [] };
    default:
      return state;
  }
};

export const OrdersProvider = ({ children }) => {
  const { user } = useAuth();
  const [state, dispatch] = useReducer(ordersReducer, {
    orders: [],
    cart: [],
    loading: false,
    error: null
  });

  const loadOrders = async () => {
    if (!user || !user.id) {
      dispatch({ type: 'SET_ORDERS', payload: [] });
      return;
    }
    
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const orders = await api.orders.getUserOrders(user.id);
      dispatch({ type: 'SET_ORDERS', payload: orders });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
    }
  };

  const createOrder = async (orderData) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const newOrder = await api.orders.createOrder({
        ...orderData,
        userId: user.id
      });
      dispatch({ type: 'ADD_ORDER', payload: newOrder });
      dispatch({ type: 'CLEAR_CART' });
      return newOrder;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const updateOrder = async (id, orderData) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const updatedOrder = await api.orders.updateOrder(id, orderData);
      dispatch({ type: 'UPDATE_ORDER', payload: updatedOrder });
      return updatedOrder;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const cancelOrder = async (id) => {
    dispatch({ type: 'SET_LOADING', payload: true });
    try {
      const cancelledOrder = await api.orders.cancelOrder(id);
      dispatch({ type: 'UPDATE_ORDER', payload: cancelledOrder });
      return cancelledOrder;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error.message });
      throw error;
    }
  };

  const addToCart = (product, quantity = 1) => {
    const cartItem = {
      id: product.id,
      productId: product.id,
      productName: product.name,
      productPrice: product.price,
      quantity,
      totalPrice: product.price * quantity
    };
    dispatch({ type: 'ADD_TO_CART', payload: cartItem });
  };

  const removeFromCart = (itemId) => {
    dispatch({ type: 'REMOVE_FROM_CART', payload: itemId });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  const getCartTotal = () => {
    return state.cart.reduce((total, item) => total + item.totalPrice, 0);
  };

  const getCartItemCount = () => {
    return state.cart.reduce((count, item) => count + item.quantity, 0);
  };

  return (
    <OrdersContext.Provider value={{
      ...state,
      loadOrders,
      createOrder,
      updateOrder,
      cancelOrder,
      addToCart,
      removeFromCart,
      clearCart,
      getCartTotal,
      getCartItemCount
    }}>
      {children}
    </OrdersContext.Provider>
  );
};

export const useOrders = () => {
  const context = useContext(OrdersContext);
  if (!context) {
    throw new Error('useOrders must be used within an OrdersProvider');
  }
  return context;
};
