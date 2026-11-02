const FALLBACK_SNAPSHOTS = {
  anaid: {
    customerName: 'Anaid Ramirez',
    aiPitch: 'Anaid, as a valued cardholder who enjoys traveling, your complimentary Cardholder Protection Plus policy was designed to protect your journeys with worldwide emergency medical coverage abroad and lost luggage protection. Cancelling leaves your upcoming trips unprotected—would you like to keep this active with our 50% renewal discount for just $4.99/mo?',
    isLive: false
  },
  edgar: {
    customerName: 'Edgar Merlo',
    aiPitch: 'Edgar, before you decide to cancel, consider how Cardholder Protection Plus supports your active lifestyle. Your policy covers sports injuries, rehabilitation, and emergency medical abroad. Keeping this active ensures you stay protected on every run for just $4.99/mo.',
    isLive: false
  }
};

function getFallbackData(customerName) {
  const lower = (customerName || '').toLowerCase();
  const snapshot = lower.includes('edgar') 
    ? FALLBACK_SNAPSHOTS.edgar 
    : FALLBACK_SNAPSHOTS.anaid;

  return {
    ...snapshot
  };
}

module.exports = {
  getFallbackData
};
