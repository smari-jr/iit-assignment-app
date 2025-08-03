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

// Track click events
router.post('/track/click', async (req, res) => {
  try {
    const {
      session_id,
      user_id = null,
      element_type,
      element_id = null,
      element_class = null,
      element_text = null,
      page_url,
      x_coordinate = null,
      y_coordinate = null,
      timestamp_client = null
    } = req.body;

    // Validation
    if (!session_id || !element_type || !page_url) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['session_id', 'element_type', 'page_url']
      });
    }

    const userAgent = req.headers['user-agent'];
    const ipAddress = getClientIP(req);
    const { device_type, browser, os } = parseUserAgent(userAgent);
    const timestamp = new Date();

    const clickData = {
      id: uuidv4(),
      session_id,
      user_id,
      timestamp,
      element_type,
      element_id,
      element_class,
      element_text,
      page_url,
      x_coordinate,
      y_coordinate,
      timestamp_client: timestamp_client ? new Date(timestamp_client) : null,
      user_agent: userAgent,
      ip_address: ipAddress,
      device_type,
      browser,
      os,
      created_at: timestamp
    };

    // Store in PostgreSQL
    const db = req.app.get('db');
    await db.query(`
      INSERT INTO analytics.click_events 
      (id, session_id, user_id, timestamp, element_type, element_id, element_class, 
       element_text, page_url, x_coordinate, y_coordinate, timestamp_client, 
       user_agent, ip_address, device_type, browser, os, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
    `, [
      clickData.id, clickData.session_id, clickData.user_id, clickData.timestamp,
      clickData.element_type, clickData.element_id, clickData.element_class,
      clickData.element_text, clickData.page_url, clickData.x_coordinate,
      clickData.y_coordinate, clickData.timestamp_client, clickData.user_agent,
      clickData.ip_address, clickData.device_type, clickData.browser,
      clickData.os, clickData.created_at
    ]);

    // Store in ClickHouse for analytics
    try {
      const clickhouse = req.app.get('clickhouse');
      await clickhouse.insert({
        table: 'analytics.click_events',
        values: [{
          id: clickData.id,
          session_id: clickData.session_id,
          user_id: clickData.user_id,
          timestamp: clickData.timestamp.toISOString(),
          element_type: clickData.element_type,
          element_id: clickData.element_id || '',
          element_class: clickData.element_class || '',
          element_text: clickData.element_text || '',
          page_url: clickData.page_url,
          x_coordinate: clickData.x_coordinate || 0,
          y_coordinate: clickData.y_coordinate || 0,
          timestamp_client: clickData.timestamp_client ? clickData.timestamp_client.toISOString() : '',
          user_agent: clickData.user_agent || '',
          ip_address: clickData.ip_address,
          device_type: clickData.device_type,
          browser: clickData.browser,
          os: clickData.os,
          created_at: clickData.created_at.toISOString()
        }],
        format: 'JSONEachRow'
      });
      console.log('🖱️ Click event stored in ClickHouse for analytics');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse insert failed, using PostgreSQL only:', clickhouseError.message);
    }

    res.status(201).json({
      message: 'Click event tracked successfully',
      click_id: clickData.id,
      timestamp: clickData.timestamp
    });

  } catch (error) {
    console.error('Error tracking click event:', error);
    res.status(500).json({
      error: 'Failed to track click event',
      message: error.message
    });
  }
});

// Track scroll depth events
router.post('/track/scroll', async (req, res) => {
  try {
    const {
      session_id,
      user_id = null,
      page_url,
      scroll_depth_percent,
      max_scroll_depth_percent = null,
      page_height = null,
      viewport_height = null,
      scroll_time_seconds = 0,
      timestamp_client = null
    } = req.body;

    // Validation
    if (!session_id || !page_url || scroll_depth_percent === undefined) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['session_id', 'page_url', 'scroll_depth_percent']
      });
    }

    const userAgent = req.headers['user-agent'];
    const ipAddress = getClientIP(req);
    const { device_type, browser, os } = parseUserAgent(userAgent);
    const timestamp = new Date();

    const scrollData = {
      id: uuidv4(),
      session_id,
      user_id,
      timestamp,
      page_url,
      scroll_depth_percent,
      max_scroll_depth_percent,
      page_height,
      viewport_height,
      scroll_time_seconds,
      timestamp_client: timestamp_client ? new Date(timestamp_client) : null,
      user_agent: userAgent,
      ip_address: ipAddress,
      device_type,
      browser,
      os,
      created_at: timestamp
    };

    // Store in PostgreSQL
    const db = req.app.get('db');
    await db.query(`
      INSERT INTO analytics.scroll_events 
      (id, session_id, user_id, timestamp, page_url, scroll_depth_percent, 
       max_scroll_depth_percent, page_height, viewport_height, scroll_time_seconds,
       timestamp_client, user_agent, ip_address, device_type, browser, os, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)
    `, [
      scrollData.id, scrollData.session_id, scrollData.user_id, scrollData.timestamp,
      scrollData.page_url, scrollData.scroll_depth_percent, scrollData.max_scroll_depth_percent,
      scrollData.page_height, scrollData.viewport_height, scrollData.scroll_time_seconds,
      scrollData.timestamp_client, scrollData.user_agent, scrollData.ip_address,
      scrollData.device_type, scrollData.browser, scrollData.os, scrollData.created_at
    ]);

    // Store in ClickHouse for analytics
    try {
      const clickhouse = req.app.get('clickhouse');
      await clickhouse.insert({
        table: 'analytics.scroll_events',
        values: [{
          id: scrollData.id,
          session_id: scrollData.session_id,
          user_id: scrollData.user_id,
          timestamp: scrollData.timestamp.toISOString(),
          page_url: scrollData.page_url,
          scroll_depth_percent: scrollData.scroll_depth_percent,
          max_scroll_depth_percent: scrollData.max_scroll_depth_percent || 0,
          page_height: scrollData.page_height || 0,
          viewport_height: scrollData.viewport_height || 0,
          scroll_time_seconds: scrollData.scroll_time_seconds,
          timestamp_client: scrollData.timestamp_client ? scrollData.timestamp_client.toISOString() : '',
          user_agent: scrollData.user_agent || '',
          ip_address: scrollData.ip_address,
          device_type: scrollData.device_type,
          browser: scrollData.browser,
          os: scrollData.os,
          created_at: scrollData.created_at.toISOString()
        }],
        format: 'JSONEachRow'
      });
      console.log('📜 Scroll event stored in ClickHouse for analytics');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse insert failed, using PostgreSQL only:', clickhouseError.message);
    }

    res.status(201).json({
      message: 'Scroll event tracked successfully',
      scroll_id: scrollData.id,
      timestamp: scrollData.timestamp
    });

  } catch (error) {
    console.error('Error tracking scroll event:', error);
    res.status(500).json({
      error: 'Failed to track scroll event',
      message: error.message
    });
  }
});

// Track session data
router.post('/track/session', async (req, res) => {
  try {
    const {
      session_id,
      user_id = null,
      session_start_time,
      session_end_time = null,
      session_duration_seconds = null,
      pages_visited = 0,
      total_clicks = 0,
      total_scroll_events = 0,
      bounce_rate = null,
      is_active = true,
      exit_page = null,
      referrer_source = null
    } = req.body;

    // Validation
    if (!session_id || !session_start_time) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['session_id', 'session_start_time']
      });
    }

    const userAgent = req.headers['user-agent'];
    const ipAddress = getClientIP(req);
    const { device_type, browser, os } = parseUserAgent(userAgent);
    const timestamp = new Date();

    const sessionData = {
      id: uuidv4(),
      session_id,
      user_id,
      timestamp,
      session_start_time: new Date(session_start_time),
      session_end_time: session_end_time ? new Date(session_end_time) : null,
      session_duration_seconds,
      pages_visited,
      total_clicks,
      total_scroll_events,
      bounce_rate,
      is_active,
      exit_page,
      referrer_source,
      user_agent: userAgent,
      ip_address: ipAddress,
      device_type,
      browser,
      os,
      created_at: timestamp
    };

    // Store in PostgreSQL  
    const db = req.app.get('db');
    await db.query(`
      INSERT INTO analytics.session_data 
      (id, session_id, user_id, timestamp, session_start_time, session_end_time,
       session_duration_seconds, pages_visited, total_clicks, total_scroll_events,
       bounce_rate, is_active, exit_page, referrer_source, user_agent, 
       ip_address, device_type, browser, os, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
    `, [
      sessionData.id, sessionData.session_id, sessionData.user_id, sessionData.timestamp,
      sessionData.session_start_time, sessionData.session_end_time, sessionData.session_duration_seconds,
      sessionData.pages_visited, sessionData.total_clicks, sessionData.total_scroll_events,
      sessionData.bounce_rate, sessionData.is_active, sessionData.exit_page,
      sessionData.referrer_source, sessionData.user_agent, sessionData.ip_address,
      sessionData.device_type, sessionData.browser, sessionData.os, sessionData.created_at
    ]);

    // Store in ClickHouse for analytics
    try {
      const clickhouse = req.app.get('clickhouse');
      await clickhouse.insert({
        table: 'analytics.session_data',
        values: [{
          id: sessionData.id,
          session_id: sessionData.session_id,
          user_id: sessionData.user_id,
          timestamp: sessionData.timestamp.toISOString(),
          session_start_time: sessionData.session_start_time.toISOString(),
          session_end_time: sessionData.session_end_time ? sessionData.session_end_time.toISOString() : '',
          session_duration_seconds: sessionData.session_duration_seconds || 0,
          pages_visited: sessionData.pages_visited,
          total_clicks: sessionData.total_clicks,
          total_scroll_events: sessionData.total_scroll_events,
          bounce_rate: sessionData.bounce_rate || 0,
          is_active: sessionData.is_active ? 1 : 0,
          exit_page: sessionData.exit_page || '',
          referrer_source: sessionData.referrer_source || '',
          user_agent: sessionData.user_agent || '',
          ip_address: sessionData.ip_address,
          device_type: sessionData.device_type,
          browser: sessionData.browser,
          os: sessionData.os,
          created_at: sessionData.created_at.toISOString()
        }],
        format: 'JSONEachRow'
      });
      console.log('⏱️ Session data stored in ClickHouse for analytics');
    } catch (clickhouseError) {
      console.warn('⚠️ ClickHouse insert failed, using PostgreSQL only:', clickhouseError.message);
    }

    res.status(201).json({
      message: 'Session data tracked successfully',
      session_data_id: sessionData.id,
      timestamp: sessionData.timestamp
    });

  } catch (error) {
    console.error('Error tracking session data:', error);
    res.status(500).json({
      error: 'Failed to track session data',
      message: error.message
    });
  }
});

// Get page visit analytics from ClickHouse (or fallback to PostgreSQL)
router.get('/page-visits', async (req, res) => {
  try {
    const {
      start_date,
      end_date,
      path,
      user_id,
      limit = 100,
      offset = 0
    } = req.query;

    let query = '';
    let queryParams = [];

    // Try ClickHouse first for better performance on large datasets
    try {
      const clickhouse = req.app.get('clickhouse');
      
      query = `
        SELECT 
          path,
          COUNT(*) as visit_count,
          COUNT(DISTINCT session_id) as unique_sessions,
          COUNT(DISTINCT user_id) as unique_users,
          AVG(duration_seconds) as avg_duration,
          device_type,
          browser,
          country
        FROM analytics.page_visits
        WHERE 1=1
      `;

      if (start_date) query += ` AND timestamp >= '${start_date}'`;
      if (end_date) query += ` AND timestamp <= '${end_date}'`;
      if (path) query += ` AND path = '${path}'`;
      if (user_id) query += ` AND user_id = '${user_id}'`;

      query += `
        GROUP BY path, device_type, browser, country
        ORDER BY visit_count DESC
        LIMIT ${parseInt(limit)}
        OFFSET ${parseInt(offset)}
      `;

      const result = await clickhouse.query({
        query,
        format: 'JSONEachRow'
      });

      const data = await result.json();
      
      res.json({
        data,
        source: 'clickhouse',
        total: data.length
      });

    } catch (clickhouseError) {
      console.warn('ClickHouse query failed, falling back to PostgreSQL:', clickhouseError.message);
      
      // Fallback to PostgreSQL
      const db = req.app.get('db');
      
      query = `
        SELECT 
          path,
          COUNT(*) as visit_count,
          COUNT(DISTINCT session_id) as unique_sessions,
          COUNT(DISTINCT user_id) as unique_users,
          AVG(duration_seconds) as avg_duration,
          device_type,
          browser,
          country
        FROM analytics.page_visits
        WHERE 1=1
      `;

      let paramIndex = 1;
      if (start_date) {
        query += ` AND timestamp >= $${paramIndex++}`;
        queryParams.push(start_date);
      }
      if (end_date) {
        query += ` AND timestamp <= $${paramIndex++}`;
        queryParams.push(end_date);
      }
      if (path) {
        query += ` AND path = $${paramIndex++}`;
        queryParams.push(path);
      }
      if (user_id) {
        query += ` AND user_id = $${paramIndex++}`;
        queryParams.push(user_id);
      }

      query += `
        GROUP BY path, device_type, browser, country
        ORDER BY visit_count DESC
        LIMIT $${paramIndex++} OFFSET $${paramIndex++}
      `;
      
      queryParams.push(parseInt(limit), parseInt(offset));

      const result = await db.query(query, queryParams);
      
      res.json({
        data: result.rows,
        source: 'postgresql',
        total: result.rows.length
      });
    }

  } catch (error) {
    console.error('Error getting page visits:', error);
    res.status(500).json({
      error: 'Failed to retrieve page visits',
      message: error.message
    });
  }
});

// Get analytics dashboard data
router.get('/dashboard', async (req, res) => {
  try {
    const { date_range = '7d' } = req.query;
    
    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();
    
    switch (date_range) {
      case '1d':
        startDate.setDate(endDate.getDate() - 1);
        break;
      case '7d':
        startDate.setDate(endDate.getDate() - 7);
        break;
      case '30d':
        startDate.setDate(endDate.getDate() - 30);
        break;
      default:
        startDate.setDate(endDate.getDate() - 7);
    }

    const db = req.app.get('db');
    
    // Get basic metrics
    const pageVisitsResult = await db.query(`
      SELECT 
        COUNT(*) as total_visits,
        COUNT(DISTINCT session_id) as unique_sessions,
        COUNT(DISTINCT user_id) as unique_users,
        AVG(duration_seconds) as avg_duration
      FROM analytics.page_visits 
      WHERE timestamp >= $1 AND timestamp <= $2
    `, [startDate, endDate]);

    const eventsResult = await db.query(`
      SELECT 
        COUNT(*) as total_events,
        COUNT(DISTINCT event_type) as unique_event_types
      FROM analytics.events 
      WHERE timestamp >= $1 AND timestamp <= $2
    `, [startDate, endDate]);

    // Get top pages
    const topPagesResult = await db.query(`
      SELECT path, COUNT(*) as visits
      FROM analytics.page_visits 
      WHERE timestamp >= $1 AND timestamp <= $2
      GROUP BY path
      ORDER BY visits DESC
      LIMIT 10
    `, [startDate, endDate]);

    // Get device breakdown
    const deviceResult = await db.query(`
      SELECT device_type, COUNT(*) as count
      FROM analytics.page_visits 
      WHERE timestamp >= $1 AND timestamp <= $2 AND device_type IS NOT NULL
      GROUP BY device_type
    `, [startDate, endDate]);

    res.json({
      date_range: {
        start: startDate,
        end: endDate,
        period: date_range
      },
      metrics: {
        page_visits: pageVisitsResult.rows[0],
        events: eventsResult.rows[0]
      },
      top_pages: topPagesResult.rows,
      device_breakdown: deviceResult.rows
    });

  } catch (error) {
    console.error('Error getting dashboard data:', error);
    res.status(500).json({
      error: 'Failed to retrieve dashboard data',
      message: error.message
    });
  }
});

// ==== DATA SEEDING ENDPOINT FOR DEMO ====

// Seed sample analytics data for demonstration
router.post('/seed-sample-data', async (req, res) => {
  try {
    const db = req.app.get('db');
    const clickhouse = req.app.get('clickhouse');
    
    // Sample data for the last 30 days
    const sampleData = [];
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 30);
    
    // Generate sample page visits
    for (let i = 0; i < 1000; i++) {
      const randomDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const sessionId = `session_${Math.floor(Math.random() * 200)}`;
      const userId = Math.random() > 0.3 ? `user_${Math.floor(Math.random() * 100)}` : null;
      
      const pages = ['/', '/products', '/products/gaming-chair', '/products/gaming-mouse', '/cart', '/checkout', '/profile'];
      const devices = ['desktop', 'mobile', 'tablet'];
      const browsers = ['Chrome', 'Firefox', 'Safari', 'Edge'];
      const countries = ['Singapore', 'Malaysia', 'Thailand', 'Indonesia', 'Philippines'];
      
      const pageVisit = {
        id: require('uuid').v4(),
        session_id: sessionId,
        user_id: userId,
        timestamp: randomDate.toISOString(),
        url: `https://lugx-gaming.com${pages[Math.floor(Math.random() * pages.length)]}`,
        path: pages[Math.floor(Math.random() * pages.length)],
        referrer: Math.random() > 0.5 ? 'https://google.com' : null,
        user_agent: `Mozilla/5.0 (compatible; ${browsers[Math.floor(Math.random() * browsers.length)]})`,
        ip_address: `192.168.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
        country: countries[Math.floor(Math.random() * countries.length)],
        city: 'Singapore',
        device_type: devices[Math.floor(Math.random() * devices.length)],
        browser: browsers[Math.floor(Math.random() * browsers.length)],
        os: 'Windows',
        screen_resolution: '1920x1080',
        duration_seconds: Math.floor(Math.random() * 300) + 10,
        created_at: randomDate.toISOString()
      };
      
      sampleData.push(pageVisit);
    }
    
    // Insert into ClickHouse
    await clickhouse.insert({
      table: 'analytics.page_visits',
      values: sampleData,
      format: 'JSONEachRow'
    });
    
    // Generate sample events (clicks, scrolls, etc.)
    const sampleEvents = [];
    for (let i = 0; i < 500; i++) {
      const randomDate = new Date(startDate.getTime() + Math.random() * (Date.now() - startDate.getTime()));
      const sessionId = `session_${Math.floor(Math.random() * 200)}`;
      
      const eventTypes = ['click', 'scroll', 'gaming', 'purchase'];
      const clickEvents = ['button_click', 'link_click', 'add_to_cart', 'checkout_button'];
      const scrollEvents = ['scroll_25', 'scroll_50', 'scroll_75', 'scroll_100'];
      const gamingEvents = ['game_start', 'game_end', 'level_complete', 'high_score'];
      
      const eventType = eventTypes[Math.floor(Math.random() * eventTypes.length)];
      let eventName = '';
      let properties = {};
      
      switch(eventType) {
        case 'click':
          eventName = clickEvents[Math.floor(Math.random() * clickEvents.length)];
          properties = {
            element_id: `btn_${Math.floor(Math.random() * 10)}`,
            page_url: '/products'
          };
          break;
        case 'scroll':
          eventName = scrollEvents[Math.floor(Math.random() * scrollEvents.length)];
          properties = {
            scroll_depth: eventName.split('_')[1],
            page_height: 2000
          };
          break;
        case 'gaming':
          eventName = gamingEvents[Math.floor(Math.random() * gamingEvents.length)];
          properties = {
            game_id: `game_${Math.floor(Math.random() * 5)}`,
            score: Math.floor(Math.random() * 50000),
            level: Math.floor(Math.random() * 10) + 1
          };
          break;
        case 'purchase':
          eventName = 'purchase_complete';
          properties = {
            order_id: `order_${Math.floor(Math.random() * 1000)}`,
            amount: (Math.random() * 500 + 50).toFixed(2),
            currency: 'USD'
          };
          break;
      }
      
      const event = {
        id: require('uuid').v4(),
        session_id: sessionId,
        user_id: Math.random() > 0.3 ? `user_${Math.floor(Math.random() * 100)}` : null,
        timestamp: randomDate.toISOString(),
        event_type: eventType,
        event_name: eventName,
        properties: JSON.stringify(properties),
        url: 'https://lugx-gaming.com/products',
        user_agent: 'Mozilla/5.0 (compatible; Chrome)',
        ip_address: `192.168.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
        country: 'Singapore',
        city: 'Singapore',
        created_at: randomDate.toISOString()
      };
      
      sampleEvents.push(event);
    }
    
    // Insert events into ClickHouse
    await clickhouse.insert({
      table: 'analytics.events',
      values: sampleEvents,
      format: 'JSONEachRow'
    });
    
    res.json({
      message: 'Sample analytics data seeded successfully',
      page_visits_created: sampleData.length,
      events_created: sampleEvents.length,
      data_range: {
        start: startDate.toISOString(),
        end: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('Error seeding sample data:', error);
    res.status(500).json({
      error: 'Failed to seed sample data',
      message: error.message
    });
  }
});

// ==== QUICKSIGHT-READY ANALYTICS ENDPOINTS ====

// Get real-time metrics for QuickSight dashboard
router.get('/quicksight/metrics', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(), // Last 7 days
      end_date = new Date().toISOString()
    } = req.query;

    const clickhouse = req.app.get('clickhouse');
    
    // Core metrics query optimized for QuickSight from ClickHouse
    const metricsQuery = `
      WITH daily_stats AS (
        SELECT 
          toDate(timestamp) as date,
          count(*) as page_views,
          uniq(session_id) as unique_sessions,
          uniq(user_id) as unique_users,
          avg(duration_seconds) as avg_session_duration,
          uniq(ip_address) as unique_visitors
        FROM analytics.page_visits 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}')
        GROUP BY toDate(timestamp)
      ),
      device_stats AS (
        SELECT 
          toDate(timestamp) as date,
          device_type,
          browser,
          os,
          count(*) as visits
        FROM analytics.page_visits 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}')
        GROUP BY toDate(timestamp), device_type, browser, os
      ),
      geo_stats AS (
        SELECT 
          toDate(timestamp) as date,
          country,
          city,
          count(*) as visits
        FROM analytics.page_visits 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}') AND country != ''
        GROUP BY toDate(timestamp), country, city
      ),
      page_stats AS (
        SELECT 
          toDate(timestamp) as date,
          path as page_path,
          count(*) as page_views,
          avg(duration_seconds) as avg_time_on_page
        FROM analytics.page_visits 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}')
        GROUP BY toDate(timestamp), path
      ),
      event_stats AS (
        SELECT 
          toDate(timestamp) as date,
          event_type,
          event_name,
          count(*) as event_count
        FROM analytics.events 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}')
        GROUP BY toDate(timestamp), event_type, event_name
      )
      SELECT 
        d.date,
        d.page_views,
        d.unique_sessions,
        d.unique_users,
        round(d.avg_session_duration, 2) as avg_session_duration,
        d.unique_visitors,
        ds.device_type,
        ds.browser,
        ds.os,
        ds.visits as device_visits,
        gs.country,
        gs.city,
        gs.visits as geo_visits,
        ps.page_path,
        ps.page_views as page_page_views,
        round(ps.avg_time_on_page, 2) as avg_time_on_page,
        es.event_type,
        es.event_name,
        es.event_count
      FROM daily_stats d
      LEFT JOIN device_stats ds ON d.date = ds.date
      LEFT JOIN geo_stats gs ON d.date = gs.date  
      LEFT JOIN page_stats ps ON d.date = ps.date
      LEFT JOIN event_stats es ON d.date = es.date
      ORDER BY d.date DESC, ds.visits DESC, gs.visits DESC, ps.page_views DESC
      LIMIT 1000
    `;

    const result = await clickhouse.query({
      query: metricsQuery,
      format: 'JSONEachRow'
    });
    
    const data = await result.json();
    
    res.json({
      data: data,
      metadata: {
        start_date,
        end_date,
        total_records: data.length,
        generated_at: new Date().toISOString(),
        data_source: 'clickhouse_analytics',
        optimized_for: 'quicksight'
      }
    });

  } catch (error) {
    console.error('Error getting QuickSight metrics:', error);
    res.status(500).json({
      error: 'Failed to retrieve QuickSight metrics',
      message: error.message
    });
  }
});

// Get user journey data for QuickSight
router.get('/quicksight/user-journey', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      end_date = new Date().toISOString()
    } = req.query;

    const db = req.app.get('db');
    
    const journeyQuery = `
      WITH user_sessions AS (
        SELECT 
          session_id,
          user_id,
          MIN(timestamp) as session_start,
          MAX(timestamp) as session_end,
          COUNT(*) as page_views,
          SUM(duration_seconds) as total_session_time,
          ARRAY_AGG(path ORDER BY timestamp) as page_sequence,
          ARRAY_AGG(timestamp ORDER BY timestamp) as timestamp_sequence,
          device_type,
          browser,
          country,
          city
        FROM analytics.page_visits 
        WHERE timestamp >= $1 AND timestamp <= $2
        GROUP BY session_id, user_id, device_type, browser, country, city
      ),
      session_events AS (
        SELECT 
          session_id,
          COUNT(*) as total_events,
          ARRAY_AGG(DISTINCT event_type) as event_types,
          ARRAY_AGG(event_name ORDER BY timestamp) as event_sequence
        FROM analytics.events 
        WHERE timestamp >= $1 AND timestamp <= $2
        GROUP BY session_id
      )
      SELECT 
        us.session_id,
        us.user_id,
        us.session_start,
        us.session_end,
        us.page_views,
        us.total_session_time,
        us.page_sequence,
        us.timestamp_sequence,
        us.device_type,
        us.browser,
        us.country,
        us.city,
        COALESCE(se.total_events, 0) as total_events,
        se.event_types,
        se.event_sequence,
        EXTRACT(EPOCH FROM (us.session_end - us.session_start)) as session_duration_seconds
      FROM user_sessions us
      LEFT JOIN session_events se ON us.session_id = se.session_id
      ORDER BY us.session_start DESC
      LIMIT 10000
    `;

    const result = await db.query(journeyQuery, [start_date, end_date]);
    
    res.json({
      data: result.rows,
      metadata: {
        start_date,
        end_date,
        total_sessions: result.rows.length,
        generated_at: new Date().toISOString(),
        data_source: 'user_journey_analytics'
      }
    });

  } catch (error) {
    console.error('Error getting user journey data:', error);
    res.status(500).json({
      error: 'Failed to retrieve user journey data',
      message: error.message
    });
  }
});

// Get conversion funnel data for QuickSight
router.get('/quicksight/conversion-funnel', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
      end_date = new Date().toISOString()
    } = req.query;

    const db = req.app.get('db');
    
    const funnelQuery = `
      WITH funnel_steps AS (
        SELECT 
          DATE(timestamp) as date,
          session_id,
          CASE 
            WHEN path = '/' THEN 'landing_page'
            WHEN path LIKE '/products%' THEN 'product_view'
            WHEN path LIKE '/cart%' THEN 'cart_view'
            WHEN path LIKE '/checkout%' THEN 'checkout_start'
            WHEN path LIKE '/order-confirmation%' THEN 'purchase_complete'
            ELSE 'other_pages'
          END as funnel_step,
          MIN(timestamp) as step_timestamp
        FROM analytics.page_visits 
        WHERE timestamp >= $1 AND timestamp <= $2
        GROUP BY DATE(timestamp), session_id, 
                 CASE 
                   WHEN path = '/' THEN 'landing_page'
                   WHEN path LIKE '/products%' THEN 'product_view'
                   WHEN path LIKE '/cart%' THEN 'cart_view'
                   WHEN path LIKE '/checkout%' THEN 'checkout_start'
                   WHEN path LIKE '/order-confirmation%' THEN 'purchase_complete'
                   ELSE 'other_pages'
                 END
      ),
      funnel_progression AS (
        SELECT 
          date,
          funnel_step,
          COUNT(DISTINCT session_id) as unique_sessions,
          COUNT(*) as total_interactions
        FROM funnel_steps
        WHERE funnel_step != 'other_pages'
        GROUP BY date, funnel_step
      )
      SELECT 
        date,
        'landing_page' as step_name,
        1 as step_order,
        COALESCE(unique_sessions, 0) as sessions,
        COALESCE(total_interactions, 0) as interactions
      FROM funnel_progression 
      WHERE funnel_step = 'landing_page'
      
      UNION ALL
      
      SELECT 
        date,
        'product_view' as step_name,
        2 as step_order,
        COALESCE(unique_sessions, 0) as sessions,
        COALESCE(total_interactions, 0) as interactions
      FROM funnel_progression 
      WHERE funnel_step = 'product_view'
      
      UNION ALL
      
      SELECT 
        date,
        'cart_view' as step_name,
        3 as step_order,
        COALESCE(unique_sessions, 0) as sessions,
        COALESCE(total_interactions, 0) as interactions
      FROM funnel_progression 
      WHERE funnel_step = 'cart_view'
      
      UNION ALL
      
      SELECT 
        date,
        'checkout_start' as step_name,
        4 as step_order,
        COALESCE(unique_sessions, 0) as sessions,
        COALESCE(total_interactions, 0) as interactions
      FROM funnel_progression 
      WHERE funnel_step = 'checkout_start'
      
      UNION ALL
      
      SELECT 
        date,
        'purchase_complete' as step_name,
        5 as step_order,
        COALESCE(unique_sessions, 0) as sessions,
        COALESCE(total_interactions, 0) as interactions
      FROM funnel_progression 
      WHERE funnel_step = 'purchase_complete'
      
      ORDER BY date DESC, step_order ASC
    `;

    const result = await db.query(funnelQuery, [start_date, end_date]);
    
    res.json({
      data: result.rows,
      metadata: {
        start_date,
        end_date,
        total_funnel_records: result.rows.length,
        generated_at: new Date().toISOString(),
        funnel_steps: ['landing_page', 'product_view', 'cart_view', 'checkout_start', 'purchase_complete']
      }
    });

  } catch (error) {
    console.error('Error getting conversion funnel data:', error);
    res.status(500).json({
      error: 'Failed to retrieve conversion funnel data',
      message: error.message
    });
  }
});

// Get gaming analytics for QuickSight
router.get('/quicksight/gaming-analytics', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      end_date = new Date().toISOString()
    } = req.query;

    const clickhouse = req.app.get('clickhouse');
    
    const gamingQuery = `
      WITH gaming_events AS (
        SELECT 
          toDate(timestamp) as date,
          session_id,
          user_id,
          event_name,
          JSONExtractString(properties, 'game_id') as game_id,
          toFloat64OrZero(JSONExtractString(properties, 'score')) as score,
          toInt32OrZero(JSONExtractString(properties, 'level')) as level,
          toInt32OrZero(JSONExtractString(properties, 'duration')) as game_duration,
          timestamp
        FROM analytics.events 
        WHERE timestamp >= toDateTime('${start_date}') AND timestamp <= toDateTime('${end_date}')
        AND event_type = 'gaming'
      ),
      daily_gaming_stats AS (
        SELECT 
          date,
          uniq(session_id) as active_gaming_sessions,
          uniq(user_id) as active_gamers,
          count(*) as total_gaming_events,
          avg(score) as avg_score,
          max(score) as max_score,
          uniq(game_id) as unique_games_played
        FROM gaming_events
        GROUP BY date
      )
      SELECT 
        date,
        active_gaming_sessions,
        active_gamers,
        total_gaming_events,
        round(avg_score, 2) as avg_score,
        max_score,
        unique_games_played,
        round(total_gaming_events / greatest(active_gaming_sessions, 1), 2) as events_per_session
      FROM daily_gaming_stats
      ORDER BY date DESC
    `;

    const result = await clickhouse.query({
      query: gamingQuery,
      format: 'JSONEachRow'
    });
    
    const data = await result.json();
    
    res.json({
      data: data,
      metadata: {
        start_date,
        end_date,
        total_records: data.length,
        generated_at: new Date().toISOString(),
        analytics_type: 'gaming_performance',
        data_source: 'clickhouse'
      }
    });

  } catch (error) {
    console.error('Error getting gaming analytics:', error);
    res.status(500).json({
      error: 'Failed to retrieve gaming analytics',
      message: error.message
    });
  }
});

// Get click analytics specifically for QuickSight
router.get('/quicksight/click-analytics', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      end_date = new Date().toISOString()
    } = req.query;

    const clickhouse = req.app.get('clickhouse');
    
    const clickQuery = `
      SELECT 
        toDate(timestamp) as date,
        event_name as click_type,
        JSONExtractString(properties, 'element_id') as element_id,
        JSONExtractString(properties, 'page_url') as page_url,
        count(*) as click_count,
        uniq(session_id) as unique_sessions,
        uniq(user_id) as unique_users,
        country,
        device_type,
        browser
      FROM analytics.events 
      WHERE timestamp >= toDateTime('${start_date}') 
        AND timestamp <= toDateTime('${end_date}')
        AND event_type = 'click'
      GROUP BY date, event_name, JSONExtractString(properties, 'element_id'), 
               JSONExtractString(properties, 'page_url'), country, device_type, browser
      ORDER BY date DESC, click_count DESC
      LIMIT 1000
    `;

    const result = await clickhouse.query({
      query: clickQuery,
      format: 'JSONEachRow'
    });
    
    const data = await result.json();
    
    res.json({
      data: data,
      metadata: {
        start_date,
        end_date,
        total_records: data.length,
        generated_at: new Date().toISOString(),
        analytics_type: 'click_tracking',
        data_source: 'clickhouse'
      }
    });

  } catch (error) {
    console.error('Error getting click analytics:', error);
    res.status(500).json({
      error: 'Failed to retrieve click analytics',
      message: error.message
    });
  }
});

// Get scroll depth analytics for QuickSight
router.get('/quicksight/scroll-analytics', async (req, res) => {
  try {
    const { 
      start_date = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      end_date = new Date().toISOString()
    } = req.query;

    const clickhouse = req.app.get('clickhouse');
    
    const scrollQuery = `
      SELECT 
        toDate(timestamp) as date,
        event_name as scroll_depth_event,
        toInt32OrZero(JSONExtractString(properties, 'scroll_depth')) as scroll_percentage,
        count(*) as scroll_events,
        uniq(session_id) as unique_sessions,
        avg(toInt32OrZero(JSONExtractString(properties, 'page_height'))) as avg_page_height,
        country,
        device_type,
        browser
      FROM analytics.events 
      WHERE timestamp >= toDateTime('${start_date}') 
        AND timestamp <= toDateTime('${end_date}')
        AND event_type = 'scroll'
      GROUP BY date, event_name, toInt32OrZero(JSONExtractString(properties, 'scroll_depth')), 
               country, device_type, browser
      ORDER BY date DESC, scroll_percentage DESC
      LIMIT 1000
    `;

    const result = await clickhouse.query({
      query: scrollQuery,
      format: 'JSONEachRow'
    });
    
    const data = await result.json();
    
    res.json({
      data: data,
      metadata: {
        start_date,
        end_date,
        total_records: data.length,
        generated_at: new Date().toISOString(),
        analytics_type: 'scroll_depth_tracking',
        data_source: 'clickhouse'
      }
    });

  } catch (error) {
    console.error('Error getting scroll analytics:', error);
    res.status(500).json({
      error: 'Failed to retrieve scroll analytics',
      message: error.message
    });
  }
});

module.exports = router;
