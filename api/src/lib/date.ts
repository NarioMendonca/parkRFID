// "Today" follows the server timezone, set through the TZ env var

export function startOfToday() {
	const today = new Date();
	today.setHours(0, 0, 0, 0);
	return today;
}

// Formats as YYYY-MM-DD in the server timezone
export function toDateString(date: Date) {
	const year = date.getFullYear();
	const month = String(date.getMonth() + 1).padStart(2, "0");
	const day = String(date.getDate()).padStart(2, "0");
	return `${year}-${month}-${day}`;
}
