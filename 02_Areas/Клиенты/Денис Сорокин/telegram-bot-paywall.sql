-- Пользователи
CREATE TABLE users (
    id BIGINT PRIMARY KEY,  -- telegram user_id
    username VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    language_code VARCHAR(10),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Подписки
CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,  -- 'recurring', 'manual'
    status VARCHAR(50) NOT NULL,  -- 'active', 'cancelled', 'expired', 'past_due'
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    next_billing_at TIMESTAMPTZ,  -- дата следующего списания
    payment_token VARCHAR(255),  -- токен CloudPayments для рекуррентов
    cancelled_at TIMESTAMPTZ,
    expiry_notified_at TIMESTAMPTZ,  -- когда отправили уведомление об истечении
    granted_by BIGINT,  -- admin user_id для ручных подписок
    grant_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Платежи
CREATE TABLE subscriptions_payments (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    subscription_id INT REFERENCES subscriptions(id),
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    cloudpayments_transaction_id VARCHAR(255),
    status VARCHAR(50) NOT NULL,  -- 'pending', 'completed', 'failed', 'refunded'
    failure_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Индексы
CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at) WHERE status = 'active';
CREATE INDEX idx_subscriptions_next_billing ON subscriptions(next_billing_at) WHERE status = 'active' AND type = 'recurring';
CREATE INDEX idx_payments_user ON subscriptions_payments(user_id);
CREATE INDEX idx_payments_cloudpayments ON subscriptions_payments(cloudpayments_transaction_id);