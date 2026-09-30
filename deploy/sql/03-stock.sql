USE stock_service;

CREATE TABLE IF NOT EXISTS stocks (
  product_id BIGINT NOT NULL,
  available BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id),
  CONSTRAINT chk_stocks_available CHECK (available >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS stock_reservations (
  order_id CHAR(36) NOT NULL,
  product_id BIGINT NOT NULL,
  quantity BIGINT NOT NULL,
  status VARCHAR(16) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id),
  KEY idx_reservations_product (product_id),
  CONSTRAINT chk_reservations_quantity CHECK (quantity > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO stocks (product_id, available) VALUES (1, 25), (2, 40), (3, 80)
ON DUPLICATE KEY UPDATE available = available;
