/**
 * Lugx Gaming Analytics Tracking Script
 * This script should be included in the frontend to track page visits and events
 */

class LugxAnalytics {
  constructor(config = {}) {
    this.analyticsUrl = config.analyticsUrl || 'http://localhost:3003/analytics';
    this.sessionId = this.getOrCreateSessionId();
    this.userId = config.userId || null;
    this.pageStartTime = Date.now();
    
    // Auto track page views
    if (config.autoTrack !== false) {
      this.trackPageView();
      this.setupUnloadTracking();
    }
  }

  // Generate or retrieve session ID
  getOrCreateSessionId() {
    let sessionId = sessionStorage.getItem('lugx_session_id');
    if (!sessionId) {
      sessionId = this.generateUUID();
      sessionStorage.setItem('lugx_session_id', sessionId);
    }
    return sessionId;
  }

  // Generate simple UUID
  generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      const r = Math.random() * 16 | 0;
      const v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  // Get screen resolution
  getScreenResolution() {
    return `${screen.width}x${screen.height}`;
  }

  // Track page visit
  async trackPageView(customData = {}) {
    try {
      const data = {
        session_id: this.sessionId,
        user_id: this.userId,
        url: window.location.href,
        path: window.location.pathname,
        referrer: document.referrer || null,
        screen_resolution: this.getScreenResolution(),
        duration_seconds: 0, // Will be updated on page unload
        ...customData
      };

      const response = await fetch(`${this.analyticsUrl}/track/page-visit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        console.warn('Analytics: Failed to track page visit');
      }
    } catch (error) {
      console.warn('Analytics: Error tracking page visit:', error);
    }
  }

  // Track custom event
  async trackEvent(eventType, eventName, properties = {}) {
    try {
      const data = {
        session_id: this.sessionId,
        user_id: this.userId,
        event_type: eventType,
        event_name: eventName,
        properties: properties,
        url: window.location.href
      };

      const response = await fetch(`${this.analyticsUrl}/track/event`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        console.warn('Analytics: Failed to track event');
      }
    } catch (error) {
      console.warn('Analytics: Error tracking event:', error);
    }
  }

  // Track game-specific events
  trackGameEvent(eventName, gameData = {}) {
    this.trackEvent('gaming', eventName, gameData);
  }

  // Track e-commerce events
  trackPurchaseEvent(eventName, purchaseData = {}) {
    this.trackEvent('ecommerce', eventName, purchaseData);
  }

  // Track user interaction events
  trackUserAction(actionName, actionData = {}) {
    this.trackEvent('user_action', actionName, actionData);
  }

  // Setup tracking for page duration
  setupUnloadTracking() {
    const self = this;
    
    // Track page duration on unload
    window.addEventListener('beforeunload', () => {
      const duration = Math.round((Date.now() - self.pageStartTime) / 1000);
      
      // Use sendBeacon for reliable delivery
      if (navigator.sendBeacon) {
        const data = JSON.stringify({
          session_id: self.sessionId,
          user_id: self.userId,
          url: window.location.href,
          path: window.location.pathname,
          referrer: document.referrer || null,
          screen_resolution: self.getScreenResolution(),
          duration_seconds: duration
        });
        
        navigator.sendBeacon(`${self.analyticsUrl}/track/page-visit`, data);
      }
    });

    // Track visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'hidden') {
        const duration = Math.round((Date.now() - self.pageStartTime) / 1000);
        self.trackEvent('user_action', 'page_hidden', { duration_seconds: duration });
      } else {
        self.pageStartTime = Date.now(); // Reset timer when page becomes visible
        self.trackEvent('user_action', 'page_visible', {});
      }
    });
  }

  // Set user ID (for logged-in users)
  setUserId(userId) {
    this.userId = userId;
  }

  // Update session ID
  setSessionId(sessionId) {
    this.sessionId = sessionId;
    sessionStorage.setItem('lugx_session_id', sessionId);
  }
}

// Auto-initialize if in browser environment
if (typeof window !== 'undefined') {
  window.LugxAnalytics = LugxAnalytics;
  
  // Auto-initialize with default config
  window.lugxAnalytics = new LugxAnalytics({
    analyticsUrl: window.ANALYTICS_URL || 'http://localhost:3003/analytics'
  });
}

// Export for Node.js environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = LugxAnalytics;
}
