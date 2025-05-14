require('dotenv').config();
const { Telegraf } = require('telegraf');
const axios = require('axios');
const exec = require('child_process').exec;

// Define your VPS name here
const VPS_NAME = "VPS_01";  // Change this to match the name of your VPS

const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN);

// Function to send crash notifications to Telegram
async function sendTelegramMessage(message) {
  try {
    await axios.post(`https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`, {
      chat_id: process.env.TELEGRAM_CHAT_ID,
      text: message,
      parse_mode: 'Markdown'
    });
  } catch (err) {
    console.error('Error sending message:', err);
  }
}

// Function to handle crash and send notification
async function handleCrashNotification(error) {
  const message = `🚨 *VPS ${VPS_NAME} has crashed!*\n\n` +
                  `*Error Message*: ${error}\n\n` +
                  `Check the system for further diagnostics.`;
  await sendTelegramMessage(message);
}

// Function to show VPS status with /status command
bot.command('status', async (ctx) => {
  const message = `*VPS ${VPS_NAME} Status:* 🚀 Running`;
  await ctx.reply(message, { parse_mode: 'Markdown' });
});

// Function to simulate the task running in the VPS
async function runVpsTask() {
  exec('./your_task.sh', (error, stdout, stderr) => {
    if (error) {
      handleCrashNotification(error.message);  // Send crash notification if task fails
    } else {
      console.log('Task completed successfully.');
    }
  });
}

// Command to manually trigger VPS task and status
bot.command('start_task', async (ctx) => {
  const message = `🔄 Starting task on VPS ${VPS_NAME}...`;
  await ctx.reply(message, { parse_mode: 'Markdown' });
  runVpsTask();
});

// Handle start command and bot introduction
bot.command('start', (ctx) => {
  ctx.reply(
    `Welcome to the VPS Monitoring Bot! I'm monitoring the status of *VPS ${VPS_NAME}*.\n\n` +
    'Use the following commands:\n' +
    '/status - Check the VPS status\n' +
    '/start_task - Start the task on the VPS and monitor the status\n',
    { parse_mode: 'Markdown' }
  );
});

// Start the bot
bot.launch().then(() => {
  console.log(`Bot is running and monitoring *VPS ${VPS_NAME}*`);
  // Optionally, start the VPS task on launch if desired
  runVpsTask();
});

// Handle shutdown signals
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
