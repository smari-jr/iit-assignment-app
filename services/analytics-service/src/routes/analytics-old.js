const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// Helper function to extract device info from user agent
const parseUserAgent = (userAgent) => {
  if (!userAgent) return { device_type: null, browser: null, os: null };
  
  // Simple user agent parsing (in production, use a library like ua-parser-js)
  const device_type = /Mobile|Android|iPhone|iPad/.test(userAgent) ? 'mobile' : 'desktop';
  const browser = userAgent.includes('Chrome') ? 'Chrome' : 
                 userAgent.includes('Firefox') ? 'Firefox' :
                 userAgent.includes('Safari') ? 'Safari' : 'Other';
  const os = userAgent.includes('Windows') ? 'Windows' :
            userAgent.includes('Mac') ? 'MacOS' :
            userAgent.includes('Linux') ? 'Linux' :
            userAgent.includes('Android') ? 'Android' :
            userAgent.includes('iOS') ? 'iOS' : 'Other';
  
  return { device_type, browser, os };
};

// Helper function to get client IP
const getClientIP = (req) => {
  return req.headers['x-forwarded-for'] || 
         req.connection.remoteAddress || 
         req.socket.remoteAddress ||
         (req.connection.socket ? req.connection.socket.remoteAddress : null) ||
         '127.0.0.1';
};

// Track page visits - integrates with ClickHouse for high-volume data
router.post('/track/page-visit', async (req, res) => {
  try {
    const {
      session_id,
      user_id = null,
      url,
      path,
      referrer = null,
      screen_resolution = null,
      duration_seconds = 0,
      country = null,
      city = null
    } = req.body;

    // Validation
    if (!session_id || !url || !path) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['session_id', 'url', 'path']
      });
    }

    const userAgent = req.headers['user-agent'];
    const ipAddress = getClientIP(req);
    const { device_type, browser, os } = parseUserAgent(userAgent);
    const timestamp = new Date();

    const visitData = {
      id: uuidv4(),
      session_id,
      user_id,
      timestamp,
      url,
      path,
      referrer,
      user_agent: userAgent,
      ip_address: ipAddress,
      country,
      city,
      device_type,
      browser,
      os,
      screen_resolution,
      duration_seconds,
      created_at: timestamp
    };

    // Store in PostgreSQL for transactional data
    const db = req.app.get('db');
    await db.query(`
      INSERT INTO analytics.page_visits 
      (id, session_id, user_id, timestamp, url, path, referrer, user_agent, 
       ip_address, country, city, device_type, browser, os, screen_resolution, 
       duration_seconds, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
    `, [
      visitData.id, visitData.session_id, visitData.user_id, visitData.timestamp,
      visitData.url, visitData.path, visitData.referrer, visitData.user_agent,
      visitData.ip_address, visitData.country, visitData.city, visitData.device_type,
      visitData.browser, visitData.os, visitData.screen_resolution,
      visitData.duration_seconds, visitData.created_at
    ]);

    // Also store in ClickHouse for analytics (if available)
    try {
      const clickhouse = req.app.get('clickhouse');
      await clickhouse.insert({
        table: 'analytics.page_visits',
        values: [{
          id: visitData.id,
          session_id: visitData.session_id,
          user_id: visitData.user_id,
          timestamp: visitData.timestamp.toISOString(),
          url: visitData.url,
          path: visitData.path,
          referrer: visitData.referrer,
          user_agent: visitData.user_agent,
          ip_address: visitData.ip_address,
          country: visitData.country,
          city: visitData.city,
          device_type: visitData.device_type,
          browser: visitData.browser,
          os: visitData.os,
          screen_resolution: visitData.screen_resolution,
          duration_seconds: visitData.duration_seconds,
          created_at: visitData.created_at.toISOString()
        }],
        format: 'JSONEachRow'
      });
      console.log('📊 Page visit stored in ClickHouse for analytics');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse insert failed, using PostgreSQL only:', clickhouseError.message);
    }

    res.status(201).json({
      message: 'Page visit tracked successfully',
      visit_id: visitData.id,
      timestamp: visitData.timestamp
    });

  } catch (error) {
    console.error('Error tracking page visit:', error);
    res.status(500).json({
      error: 'Failed to track page visit',
      message: error.message
    });
  }
});

// Track custom events
router.post('/track/event', async (req, res) => {
  try {
    const {
      session_id,
      user_id = null,
      event_type,
      event_name,
      properties = {},
      url = null,
      country = null,
      city = null
    } = req.body;

    // Validation
    if (!session_id || !event_type || !event_name) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['session_id', 'event_type', 'event_name']
      });
    }

    const userAgent = req.headers['user-agent'];
    const ipAddress = getClientIP(req);
    const timestamp = new Date();

    const eventData = {
      id: uuidv4(),
      session_id,
      user_id,
      timestamp,
      event_type,
      event_name,
      properties: JSON.stringify(properties),
      url,
      user_agent: userAgent,
      ip_address: ipAddress,
      country,
      city,
      created_at: timestamp
    };

    // Store in PostgreSQL
    const db = req.app.get('db');
    await db.query(`
      INSERT INTO analytics.events 
      (id, session_id, user_id, timestamp, event_type, event_name, properties, 
       url, user_agent, ip_address, country, city, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
    `, [
      eventData.id, eventData.session_id, eventData.user_id, eventData.timestamp,
      eventData.event_type, eventData.event_name, eventData.properties,
      eventData.url, eventData.user_agent, eventData.ip_address,
      eventData.country, eventData.city, eventData.created_at
    ]);

    // Also store in ClickHouse for analytics
    try {
      const clickhouse = req.app.get('clickhouse');
      await clickhouse.insert({
        table: 'analytics.events',
        values: [{
          id: eventData.id,
          session_id: eventData.session_id,
          user_id: eventData.user_id,
          timestamp: eventData.timestamp.toISOString(),
          event_type: eventData.event_type,
          event_name: eventData.event_name,
          properties: eventData.properties,
          url: eventData.url,
          user_agent: eventData.user_agent,
          ip_address: eventData.ip_address,
          country: eventData.country,
          city: eventData.city,
          created_at: eventData.created_at.toISOString()
        }],
        format: 'JSONEachRow'
      });
      console.log('📊 Event stored in ClickHouse for analytics');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse insert failed, using PostgreSQL only:', clickhouseError.message);
    }

    res.status(201).json({
      message: 'Event tracked successfully',
      event_id: eventData.id,
      timestamp: eventData.timestamp
    });

  } catch (error) {
    console.error('Error tracking event:', error);
    res.status(500).json({
      error: 'Failed to track event',
      message: error.message
    });
  }
});

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Event tracking error:', error);
    res.status(500).json({ error: 'Failed to track event' });
  }
});

// Track e-commerce event
router.post('/ecommerce', extractUserInfo, async (req, res) => {
  try {
    const {
      session_id,
      user_id,
      event_type,
      product_id,
      product_name,
      product_category,
      product_price,
      quantity = 1,
      currency = 'USD'
    } = req.body;

    const total_value = product_price * quantity;

    const ecommerceEvent = {
      id: uuidv4(),
      session_id: session_id || uuidv4(),
      user_id: user_id || null,
      timestamp: new Date().toISOString(),
      event_type,
      product_id: product_id || '',
      product_name: product_name || '',
      product_category: product_category || '',
      product_price: parseFloat(product_price) || 0,
      quantity: parseInt(quantity) || 1,
      total_value,
      currency
    };

    await clickhouseClient.insert({
      table: 'ecommerce_events',
      values: [ecommerceEvent]
    });

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('E-commerce event tracking error:', error);
    res.status(500).json({ error: 'Failed to track e-commerce event' });
  }
});

// Get analytics dashboard data
router.get('/dashboard', async (req, res) => {
  try {
    const { date_from, date_to } = req.query;
    const dateFilter = date_from && date_to 
      ? `WHERE timestamp >= '${date_from}' AND timestamp <= '${date_to}'`
      : `WHERE timestamp >= now() - INTERVAL 30 DAY`;

    // Page views by day
    const pageViewsQuery = `
      SELECT 
        toDate(timestamp) as date,
        count() as views,
        uniq(session_id) as sessions,
        uniq(user_id) as users
      FROM page_views 
      ${dateFilter}
      GROUP BY date 
      ORDER BY date
    `;

    // Top pages
    const topPagesQuery = `
      SELECT 
        path,
        count() as views,
        uniq(session_id) as sessions
      FROM page_views 
      ${dateFilter}
      GROUP BY path 
      ORDER BY views DESC 
      LIMIT 10
    `;

    // Browser stats
    const browserQuery = `
      SELECT 
        browser,
        count() as sessions
      FROM page_views 
      ${dateFilter}
      GROUP BY browser 
      ORDER BY sessions DESC 
      LIMIT 10
    `;

    // Country stats
    const countryQuery = `
      SELECT 
        country,
        count() as sessions
      FROM page_views 
      ${dateFilter}
      GROUP BY country 
      ORDER BY sessions DESC 
      LIMIT 10
    `;

    const [pageViews, topPages, browserStats, countryStats] = await Promise.all([
      clickhouseClient.query({ query: pageViewsQuery }),
      clickhouseClient.query({ query: topPagesQuery }),
      clickhouseClient.query({ query: browserQuery }),
      clickhouseClient.query({ query: countryQuery })
    ]);

    res.json({
      pageViews: await pageViews.json(),
      topPages: await topPages.json(),
      browserStats: await browserStats.json(),
      countryStats: await countryStats.json()
    });
  } catch (error) {
    console.error('Dashboard data error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

// Analytics tracking script
router.get('/script.js', (req, res) => {
  const script = `
(function() {
  var analyticsUrl = '${process.env.ANALYTICS_URL || '/api/analytics'}';
  var sessionId = localStorage.getItem('lugx_session_id') || generateUUID();
  localStorage.setItem('lugx_session_id', sessionId);
  
  function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
  
  function trackPageView() {
    var data = {
      session_id: sessionId,
      url: window.location.href,
      path: window.location.pathname,
      referrer: document.referrer,
      screen_resolution: screen.width + 'x' + screen.height
    };
    
    fetch(analyticsUrl + '/pageview', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }).catch(function(e) { console.error('Analytics error:', e); });
  }
  
  function trackEvent(eventType, eventName, properties) {
    var data = {
      session_id: sessionId,
      event_type: eventType,
      event_name: eventName,
      properties: properties || {},
      url: window.location.href
    };
    
    fetch(analyticsUrl + '/event', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }).catch(function(e) { console.error('Analytics error:', e); });
  }
  
  function trackEcommerce(eventType, productData) {
    var data = Object.assign({
      session_id: sessionId,
      event_type: eventType
    }, productData);
    
    fetch(analyticsUrl + '/ecommerce', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    }).catch(function(e) { console.error('Analytics error:', e); });
  }
  
  // Track initial page view
  trackPageView();
  
  // Track page changes for SPAs
  var originalPushState = history.pushState;
  history.pushState = function() {
    originalPushState.apply(history, arguments);
    setTimeout(trackPageView, 100);
  };
  
  // Export tracking functions
  window.lugxAnalytics = {
    trackEvent: trackEvent,
    trackEcommerce: trackEcommerce,
    trackPageView: trackPageView
  };
})();
  `;
  
  res.setHeader('Content-Type', 'application/javascript');
  res.send(script);
});

module.exports = router;
