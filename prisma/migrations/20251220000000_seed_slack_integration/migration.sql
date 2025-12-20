
INSERT INTO "Integration" (
    "id",
    "name",
    "slug",
    "description",
    "readme",
    "developer",
    "website",
    "logo",
    "verified",
    "category",
    "updatedAt"
) VALUES (
    'slack',
    'Slack',
    'slack',
    'Receive real-time notifications for document activity in your Slack channels.',
    'Connect your Slack workspace to receive notifications when your documents are viewed, downloaded, or shared.',
    'Papermark',
    'https://papermark.io',
    '/images/integrations/slack.png',
    true,
    'communication',
    NOW()
) ON CONFLICT ("id") DO UPDATE SET
    "name" = EXCLUDED."name",
    "slug" = EXCLUDED."slug",
    "description" = EXCLUDED."description",
    "readme" = EXCLUDED."readme",
    "developer" = EXCLUDED."developer",
    "website" = EXCLUDED."website",
    "logo" = EXCLUDED."logo",
    "verified" = EXCLUDED."verified",
    "category" = EXCLUDED."category",
    "updatedAt" = NOW();
