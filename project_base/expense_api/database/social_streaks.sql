CREATE TABLE IF NOT EXISTS friendships (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  requester_id INT NOT NULL,
  receiver_id INT NOT NULL,
  status ENUM('pending', 'accepted', 'rejected', 'blocked') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_friend_request (requester_id, receiver_id),
  KEY index_friend_receiver_status (receiver_id, status)
);

CREATE TABLE IF NOT EXISTS social_streaks (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  friendship_id BIGINT NOT NULL,
  current_streak INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_completed_date DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_friendship_streak (friendship_id)
);

CREATE TABLE IF NOT EXISTS streak_checkins (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  streak_id BIGINT NOT NULL,
  user_id INT NOT NULL,
  checkin_date DATE NOT NULL,
  private_status ENUM('mindful', 'paused_purchase', 'unplanned_purchase', 'observed') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_daily_streak_checkin (streak_id, user_id, checkin_date),
  KEY index_streak_checkin_date (streak_id, checkin_date)
);

CREATE TABLE IF NOT EXISTS streak_nudges (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  streak_id BIGINT NOT NULL,
  sender_id INT NOT NULL,
  receiver_id INT NOT NULL,
  nudge_date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_daily_nudge (streak_id, sender_id, nudge_date)
);
