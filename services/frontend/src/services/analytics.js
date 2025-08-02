// Web Analytics Tracking Service
// Tracks page views, clicks, scroll depth, and session data to ClickHouse via analytics service

class WebAnalytics {
  constructor() {
    this.sessionId = this.generateSessionId();
    this.userId = null;
    this.isActive = true;
    this.sessionStartTime = new Date();
    this.currentPageStartTime = new Date();
    this.pageViews = [];
    this.clicks = [];
    this.scrollEvents = [];
    
    // Scroll tracking variables
    this.maxScrollDepth = 0;
    this.scrollDepthMilestones = [25, 50, 75, 90, 100];
    this.scrollDepthReached = new Set();
    
    // Performance tracking
    this.performanceData = {};
    
    this.initializeTracking();
    this.setupEventListeners();
  }

  generateSessionId() {
    return 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
  }

  initializeTracking() {
    // Get user ID from localStorage if authenticated
    const token = localStorage.getItem('authToken');
    if (token) {
      try {
        const payload = JSON.parse(atob(token.split('.')[1]));
        this.userId = payload.userId;
      } catch (error) {
        console.warn('Could not parse auth token for analytics:', error);
      }
    }

    // Track initial page view
    this.trackPageView();
    
    // Track session start
    this.trackSessionStart();

    console.log('📊 Analytics initialized:', {
      sessionId: this.sessionId,
      userId: this.userId
    });
  }

  setupEventListeners() {
    // Page visibility change (tab switching, browser minimizing)
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.trackPageEnd();
      } else {
        this.trackPageView();
      }
    });

    // Before page unload
    window.addEventListener('beforeunload', () => {
      this.trackPageEnd();
      this.trackSessionEnd();
    });

    // Scroll tracking
    let scrollTimeout;
    window.addEventListener('scroll', () => {
      clearTimeout(scrollTimeout);
      scrollTimeout = setTimeout(() => {
        this.trackScrollDepth();
      }, 100); // Throttle scroll events
    });

    // Click tracking
    document.addEventListener('click', (event) => {
      this.trackClick(event);
    });

    // Performance tracking
    window.addEventListener('load', () => {
      this.trackPerformance();
    });

    // Route changes (for SPAs)
    window.addEventListener('popstate', () => {
      setTimeout(() => {
        this.trackPageView();
      }, 100);
    });
  }

  async trackPageView() {
    const pageData = {
      session_id: this.sessionId,
      user_id: this.userId,
      url: window.location.href,
      path: window.location.pathname,
      referrer: document.referrer || null,
      screen_resolution: `${window.screen.width}x${window.screen.height}`,
      duration_seconds: 0,
      country: null, // Could be enhanced with IP geolocation
      city: null
    };

    this.currentPageStartTime = new Date();
    this.maxScrollDepth = 0;
    this.scrollDepthReached.clear();

    try {
      const response = await fetch('/api/analytics/track/page-visit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(pageData)
      });

      if (response.ok) {
        console.log('📄 Page visit tracked:', pageData.path);
      }
    } catch (error) {
      console.error('Failed to track page visit:', error);
    }

    this.pageViews.push(pageData);
  }

  async trackPageEnd() {
    if (this.currentPageStartTime) {
      const duration = Math.round((new Date() - this.currentPageStartTime) / 1000);
      
      const pageEndData = {
        session_id: this.sessionId,
        user_id: this.userId,
        url: window.location.href,
        path: window.location.pathname,
        referrer: document.referrer || null,
        screen_resolution: `${window.screen.width}x${window.screen.height}`,
        duration_seconds: duration,
        country: null,
        city: null
      };

      try {
        await fetch('/api/analytics/track/page-visit', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(pageEndData)
        });

        console.log('📄 Page end tracked:', pageEndData.path, `${duration}s`);
      } catch (error) {
        console.error('Failed to track page end:', error);
      }
    }
  }

  async trackClick(event) {
    const element = event.target;
    const rect = element.getBoundingClientRect();
    
    const clickData = {
      session_id: this.sessionId,
      user_id: this.userId,
      element_type: element.tagName.toLowerCase(),
      element_id: element.id || null,
      element_class: element.className || null,
      element_text: element.textContent?.slice(0, 200) || null,
      page_url: window.location.href,
      x_coordinate: Math.round(event.clientX),
      y_coordinate: Math.round(event.clientY),
      timestamp_client: new Date().toISOString()
    };

    try {
      const response = await fetch('/api/analytics/track/click', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(clickData)
      });

      if (response.ok) {
        console.log('🖱️ Click tracked:', clickData.element_type, clickData.element_text?.slice(0, 30));
      }
    } catch (error) {
      console.error('Failed to track click:', error);
    }

    this.clicks.push(clickData);
  }

  async trackScrollDepth() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    const windowHeight = window.innerHeight;
    const documentHeight = Math.max(
      document.body.scrollHeight,
      document.body.offsetHeight,
      document.documentElement.clientHeight,
      document.documentElement.scrollHeight,
      document.documentElement.offsetHeight
    );

    const scrollPercent = Math.round((scrollTop + windowHeight) / documentHeight * 100);
    
    // Update max scroll depth
    if (scrollPercent > this.maxScrollDepth) {
      this.maxScrollDepth = scrollPercent;
    }

    // Track milestone scroll depths
    for (const milestone of this.scrollDepthMilestones) {
      if (scrollPercent >= milestone && !this.scrollDepthReached.has(milestone)) {
        this.scrollDepthReached.add(milestone);
        
        const scrollData = {
          session_id: this.sessionId,
          user_id: this.userId,
          page_url: window.location.href,
          scroll_depth_percent: milestone,
          max_scroll_depth_percent: this.maxScrollDepth,
          page_height: documentHeight,
          viewport_height: windowHeight,
          scroll_time_seconds: Math.round((new Date() - this.currentPageStartTime) / 1000),
          timestamp_client: new Date().toISOString()
        };

        try {
          const response = await fetch('/api/analytics/track/scroll', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(scrollData)
          });

          if (response.ok) {
            console.log('📜 Scroll milestone tracked:', `${milestone}%`);
          }
        } catch (error) {
          console.error('Failed to track scroll:', error);
        }

        this.scrollEvents.push(scrollData);
      }
    }
  }

  async trackSessionStart() {
    const sessionData = {
      session_id: this.sessionId,
      user_id: this.userId,
      session_start_time: this.sessionStartTime.toISOString(),
      session_end_time: null,
      session_duration_seconds: null,
      pages_visited: 1,
      total_clicks: 0,
      total_scroll_events: 0,
      bounce_rate: null,
      is_active: true,
      exit_page: null,
      referrer_source: document.referrer || null
    };

    try {
      const response = await fetch('/api/analytics/track/session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(sessionData)
      });

      if (response.ok) {
        console.log('⏱️ Session started:', this.sessionId);
      }
    } catch (error) {
      console.error('Failed to track session start:', error);
    }
  }

  async trackSessionEnd() {
    const sessionEndTime = new Date();
    const sessionDuration = Math.round((sessionEndTime - this.sessionStartTime) / 1000);
    
    const sessionData = {
      session_id: this.sessionId,
      user_id: this.userId,
      session_start_time: this.sessionStartTime.toISOString(),
      session_end_time: sessionEndTime.toISOString(),
      session_duration_seconds: sessionDuration,
      pages_visited: this.pageViews.length,
      total_clicks: this.clicks.length,
      total_scroll_events: this.scrollEvents.length,
      bounce_rate: this.pageViews.length === 1 ? 100 : 0,
      is_active: false,
      exit_page: window.location.pathname,
      referrer_source: document.referrer || null
    };

    try {
      // Use sendBeacon for reliable data sending on page unload
      const data = JSON.stringify(sessionData);
      if (navigator.sendBeacon) {
        navigator.sendBeacon('/api/analytics/track/session', data);
      } else {
        await fetch('/api/analytics/track/session', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: data
        });
      }

      console.log('⏱️ Session ended:', this.sessionId, `${sessionDuration}s`);
    } catch (error) {
      console.error('Failed to track session end:', error);
    }
  }

  async trackCustomEvent(eventType, eventName, properties = {}) {
    const eventData = {
      session_id: this.sessionId,
      user_id: this.userId,
      event_type: eventType,
      event_name: eventName,
      properties: properties,
      url: window.location.href,
      country: null,
      city: null
    };

    try {
      const response = await fetch('/api/analytics/track/event', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(eventData)
      });

      if (response.ok) {
        console.log('🎯 Custom event tracked:', eventType, eventName);
      }
    } catch (error) {
      console.error('Failed to track custom event:', error);
    }
  }

  trackPerformance() {
    if (window.performance && window.performance.timing) {
      const timing = window.performance.timing;
      const performanceData = {
        page_load_time: timing.loadEventEnd - timing.navigationStart,
        dom_ready_time: timing.domContentLoadedEventEnd - timing.navigationStart,
        first_paint_time: timing.responseStart - timing.navigationStart,
        dns_lookup_time: timing.domainLookupEnd - timing.domainLookupStart,
        server_response_time: timing.responseEnd - timing.requestStart
      };

      this.trackCustomEvent('performance', 'page_load', performanceData);
    }
  }

  // Utility method to update user ID when user logs in
  setUserId(userId) {
    this.userId = userId;
    console.log('👤 Analytics user ID updated:', userId);
  }

  // Get analytics summary for current session
  getSessionSummary() {
    return {
      sessionId: this.sessionId,
      userId: this.userId,
      sessionDuration: Math.round((new Date() - this.sessionStartTime) / 1000),
      pageViews: this.pageViews.length,
      clicks: this.clicks.length,
      scrollEvents: this.scrollEvents.length,
      maxScrollDepth: this.maxScrollDepth
    };
  }
}

// Create singleton instance
const analytics = new WebAnalytics();

export default analytics;
