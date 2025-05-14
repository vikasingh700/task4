require('dotenv').config();
const { Telegraf } = require('telegraf');
const LocalSession = require('telegraf-session-local');
const axios = require('axios');
const exec = require('child_process').exec;

// Initialize bot
const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN);
const session = new LocalSession({
  getSessionKey: (ctx) => ctx.from && ctx.from.id ? ctx.from.id.toString() : undefined
});
bot.use(session.middleware());

// VPS details
const vpsDetails = {
  VPS1: {
    name: 'VPS-1',
    status: 'running',
  },
  VPS2: {
    name: 'VPS-2',
    status: 'running',
  },
  VPS3: {
    name: 'VPS-3',
    status: 'running',
  },
  VPS4: {
    name: 'VPS-4',
    status: 'running',
  }
};

// Function to send a message to Telegram
const sendTelegramMessage = async (message) => {
  try {
    await bot.telegram.sendMessage(process.env.TELEGRAM_CHAT_ID, message);
  } catch (error) {
    console.error('Error sending message to Telegram:', error);
  }
};

// Function to report crash
const reportCrash = (vpsName, error) => {
  const crashMessage = `🚨 CRASH ALERT 🚨\nVPS: ${vpsName}\nError: ${error}\nStatus: Crashed`;
  sendTelegramMessage(crashMessage);
};

// Function to check VPS status
const getVPSStatus = (vpsName) => {
  exec(`ps aux | grep run_rl_swarm.sh | grep -v grep`, (error, stdout, stderr) => {
    if (error || stderr) {
      vpsDetails[vpsName].status = 'crashed';
      reportCrash(vpsName, stderr || error);
    } else {
      vpsDetails[vpsName].status = 'running';
    }
  });
};

// Handle /status command to report current VPS status
bot.command('status', async (ctx) => {
  let statusMessage = '📊 VPS Status:\n\n';
  for (const vps in vpsDetails) {
    statusMessage += `${vpsDetails[vps].name}: ${vpsDetails[vps].status}\n`;
  }
  await ctx.reply(statusMessage);
});

// Handle /start command
bot.command('start', (ctx) => {
  ctx.reply(
    'Welcome to the VPS Watchdog Bot. Use /status to get current VPS status.\nThe bot will send alerts if any of the VPS nodes crash.'
  );
});

// Check VPS statuses every minute
setInterval(() => {
  for (const vps in vpsDetails) {
    getVPSStatus(vps);
  }
}, 60000); // Check every minute

bot.launch();
console.log('VPS Watchdog Bot is running...');
