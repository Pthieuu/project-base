CREATE TABLE IF NOT EXISTS api_rate_limits (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  action_name VARCHAR(80) NOT NULL,
  subject_hash CHAR(64) NOT NULL,
  attempted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY index_api_rate_limit_window (action_name, subject_hash, attempted_at)
);
