USE product_service;

CREATE TABLE IF NOT EXISTS products (
  id BIGINT NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  price_cents BIGINT NOT NULL,
  image_url VARCHAR(500) NOT NULL DEFAULT '',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_products_active_id (active, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO products (id, name, description, price_cents, image_url, active) VALUES
  (1, 'Everyday Canvas Tote', 'A durable cotton canvas tote for daily errands.', 12900, '', TRUE),
  (2, 'Ceramic Desk Cup', 'A glazed ceramic cup for coffee or tea.', 8900, '', TRUE),
  (3, 'Notebook Set', 'Three thread-bound notebooks with recycled paper.', 6500, '', TRUE)
ON DUPLICATE KEY UPDATE name = VALUES(name);
