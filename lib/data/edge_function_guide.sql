-- ═══════════════════════════════════════════════════════════════════════════
-- Supabase Edge Function: إرسال إشعارات FCM
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- هذا الملف يحتوي على كود Edge Function بلغة TypeScript/Deno
-- يُنشر على Supabase Edge Functions
--
-- الخطوات:
-- 1. ثبّت Supabase CLI: npm install -g supabase
-- 2. supabase functions new send-fcm-notification
-- 3. انسخ الكود من الملف أدناه
-- 4. supabase functions deploy send-fcm-notification
--
-- أو يمكنك استخدام Database Webhook بدلاً من ذلك
-- ═══════════════════════════════════════════════════════════════════════════

-- الملف: supabase/functions/send-fcm-notification/index.ts
-- المحتوى أدناه (احفظه كملف TypeScript منفصل):

/*
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// مفتاح FCM Server Key (من Firebase Console → Project Settings → Cloud Messaging)
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { record } = await req.json();
    
    // record = الصف الجديد من customer_notifications
    const notificationId = record.id;
    const customerId = record.customer_id;
    const title = record.title;
    const body = record.body;
    const type = record.type;
    const orderId = record.order_id;
    const shopId = record.shop_id;
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    if (type === 'promotion' || type === 'announcement') {
      // إشعار جماعي عبر Topic
      const topic = `shop_${shopId.replace(/-/g, '_')}`;
      await sendToTopic(topic, title, body, type, orderId);
    } else if (customerId) {
      // إشعار فردي - جلب توكنات العميل
      const { data: tokens } = await supabase
        .from('fcm_tokens')
        .select('token')
        .eq('customer_id', customerId)
        .eq('is_active', true);
      
      if (tokens && tokens.length > 0) {
        for (const { token } of tokens) {
          await sendToDevice(token, title, body, type, orderId);
        }
      }
    }
    
    // تحديث حالة الإرسال
    await supabase
      .from('customer_notifications')
      .update({ is_sent_fcm: true })
      .eq('id', notificationId);
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

async function sendToDevice(token, title, body, type, orderId) {
  const message = {
    to: token,
    notification: { title, body },
    data: { type, order_id: orderId?.toString() || '' },
    android: {
      priority: 'high',
      notification: {
        channel_id: type === 'promotion' ? 'alkafaje_promos' : 'alkafaje_orders',
        sound: 'default',
      },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  };
  
  await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify(message),
  });
}

async function sendToTopic(topic, title, body, type, orderId) {
  const message = {
    to: `/topics/${topic}`,
    notification: { title, body },
    data: { type, order_id: orderId?.toString() || '' },
    android: {
      priority: 'high',
      notification: {
        channel_id: 'alkafaje_promos',
        sound: 'default',
      },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  };
  
  await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify(message),
  });
}
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- بديل أبسط: Database Webhook
-- ═══════════════════════════════════════════════════════════════════════════
-- في Supabase Dashboard → Database → Webhooks:
-- 1. أنشئ Webhook جديد
-- 2. Table: customer_notifications
-- 3. Events: INSERT
-- 4. URL: رابط Edge Function
-- 5. هذا سيرسل FCM تلقائياً عند إضافة إشعار جديد
