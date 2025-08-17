import React, { useState, useEffect } from 'react';
import './Analytics.css';
import { analyticsAPI } from '../services/api';

const Analytics = () => {
  const [dashboardData, setDashboardData] = useState(null);
  const [pageVisitsData, setPageVisitsData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedDateRange, setSelectedDateRange] = useState('7d');

  useEffect(() => {
    loadAnalyticsData();
  }, [selectedDateRange]);

  const loadAnalyticsData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Load dashboard data
      const dashboardResponse = await analyticsAPI.getDashboard({ date_range: selectedDateRange });
      setDashboardData(dashboardResponse);

      // Load page visits data
      const pageVisitsResponse = await analyticsAPI.getPageVisits({ 
        limit: 20,
        offset: 0 
      });
      setPageVisitsData(pageVisitsResponse.data || []);

    } catch (error) {
      console.error('Error loading analytics data:', error);
      setError('Failed to load analytics data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const formatNumber = (num) => {
    if (!num) return '0';
    return new Intl.NumberFormat().format(num);
  };

  const formatDuration = (seconds) => {
    if (!seconds) return '0s';
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return minutes > 0 ? `${minutes}m ${remainingSeconds}s` : `${remainingSeconds}s`;
  };

  if (loading) {
    return (
      <div className="analytics-container">
        <div className="analytics-header">
          <h2>Analytics Dashboard</h2>
        </div>
        <div className="loading-state">
          <div className="loading-spinner"></div>
          <p>Loading analytics data...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="analytics-container">
        <div className="analytics-header">
          <h2>Analytics Dashboard</h2>
        </div>
        <div className="error-state">
          <p className="error-message">{error}</p>
          <button onClick={loadAnalyticsData} className="retry-btn">
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="analytics-container">
      <div className="analytics-header">
        <h2>Analytics Dashboard</h2>
        <div className="date-range-selector">
          <select 
            value={selectedDateRange} 
            onChange={(e) => setSelectedDateRange(e.target.value)}
            className="date-range-select"
          >
            <option value="1d">Last 24 Hours</option>
            <option value="7d">Last 7 Days</option>
            <option value="30d">Last 30 Days</option>
          </select>
        </div>
      </div>

      {/* Key Metrics */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-icon">📄</div>
          <div className="metric-content">
            <h3>Page Visits</h3>
            <div className="metric-value">
              {formatNumber(dashboardData?.metrics?.page_visits?.total_visits)}
            </div>
            <div className="metric-subtitle">
              {formatNumber(dashboardData?.metrics?.page_visits?.unique_sessions)} sessions
            </div>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-icon">👥</div>
          <div className="metric-content">
            <h3>Unique Users</h3>
            <div className="metric-value">
              {formatNumber(dashboardData?.metrics?.page_visits?.unique_users)}
            </div>
            <div className="metric-subtitle">
              Active visitors
            </div>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-icon">⏱️</div>
          <div className="metric-content">
            <h3>Avg. Duration</h3>
            <div className="metric-value">
              {formatDuration(dashboardData?.metrics?.page_visits?.avg_duration)}
            </div>
            <div className="metric-subtitle">
              Time on site
            </div>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-icon">🎯</div>
          <div className="metric-content">
            <h3>Events</h3>
            <div className="metric-value">
              {formatNumber(dashboardData?.metrics?.events?.total_events)}
            </div>
            <div className="metric-subtitle">
              {formatNumber(dashboardData?.metrics?.events?.unique_event_types)} types
            </div>
          </div>
        </div>
      </div>

      <div className="analytics-content">
        {/* Top Pages */}
        <div className="analytics-section">
          <h3>Top Pages</h3>
          <div className="top-pages-list">
            {dashboardData?.top_pages?.length > 0 ? (
              dashboardData.top_pages.map((page, index) => (
                <div key={index} className="page-item">
                  <div className="page-path">{page.path}</div>
                  <div className="page-visits">{formatNumber(page.visits)} visits</div>
                </div>
              ))
            ) : (
              <p className="no-data">No page data available</p>
            )}
          </div>
        </div>

        {/* Device Breakdown */}
        <div className="analytics-section">
          <h3>Device Breakdown</h3>
          <div className="device-breakdown">
            {dashboardData?.device_breakdown?.length > 0 ? (
              dashboardData.device_breakdown.map((device, index) => (
                <div key={index} className="device-item">
                  <div className="device-type">
                    {device.device_type === 'desktop' ? '🖥️' : 
                     device.device_type === 'mobile' ? '📱' : '📊'} 
                    {device.device_type}
                  </div>
                  <div className="device-count">{formatNumber(device.count)}</div>
                </div>
              ))
            ) : (
              <p className="no-data">No device data available</p>
            )}
          </div>
        </div>

        {/* Recent Page Visits */}
        <div className="analytics-section full-width">
          <h3>Recent Page Visits</h3>
          <div className="page-visits-table">
            {pageVisitsData.length > 0 ? (
              <table>
                <thead>
                  <tr>
                    <th>Page</th>
                    <th>Visits</th>
                    <th>Sessions</th>
                    <th>Users</th>
                    <th>Avg Duration</th>
                    <th>Device</th>
                    <th>Browser</th>
                  </tr>
                </thead>
                <tbody>
                  {pageVisitsData.map((visit, index) => (
                    <tr key={index}>
                      <td className="page-path">{visit.path}</td>
                      <td>{formatNumber(visit.visit_count)}</td>
                      <td>{formatNumber(visit.unique_sessions)}</td>
                      <td>{formatNumber(visit.unique_users)}</td>
                      <td>{formatDuration(visit.avg_duration)}</td>
                      <td>{visit.device_type}</td>
                      <td>{visit.browser}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="no-data">No recent page visits data available</p>
            )}
          </div>
        </div>
      </div>

      {/* Data Refresh Info */}
      <div className="data-info">
        <p>
          Data Range: {dashboardData?.date_range?.start ? 
            new Date(dashboardData.date_range.start).toLocaleDateString() : 'N/A'} - {' '}
          {dashboardData?.date_range?.end ? 
            new Date(dashboardData.date_range.end).toLocaleDateString() : 'N/A'}
        </p>
        <button onClick={loadAnalyticsData} className="refresh-btn">
          🔄 Refresh Data
        </button>
      </div>
    </div>
  );
};

export default Analytics;
