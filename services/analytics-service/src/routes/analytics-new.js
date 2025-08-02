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

module.exports = router;
