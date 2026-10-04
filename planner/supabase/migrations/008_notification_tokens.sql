-- Migration 008: Dedicated Notification Tokens Table for Push Notifications
-- Stores active device FCM tokens associated with authenticated users.

CREATE TABLE IF NOT EXISTS public.notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android',
    device_id TEXT NOT NULL,
    notification_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_notification_tokens_user_device UNIQUE (user_id, device_id)
);

-- Indexes for fast lookup by user and token
CREATE INDEX IF NOT EXISTS idx_notification_tokens_user_id ON public.notification_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_tokens_token ON public.notification_tokens (fcm_token);

-- Enable RLS
ALTER TABLE public.notification_tokens ENABLE ROW LEVEL SECURITY;

-- Policies: Users can view and manage only their own device tokens
CREATE POLICY "Users can view own device tokens"
    ON public.notification_tokens
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own device tokens"
    ON public.notification_tokens
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own device tokens"
    ON public.notification_tokens
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own device tokens"
    ON public.notification_tokens
    FOR DELETE
    USING (auth.uid() = user_id);
