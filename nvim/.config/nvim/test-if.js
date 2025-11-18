// Test file for context-aware code actions

function example() {
  const value = 42;

  // Place cursor inside this if statement to see special actions
  if (value > 40) {
    console.log("Value is large");
  }

  // Cursor here won't show if-specific actions
  console.log("Outside if statement");

  // Another if to test
  if (value < 100) {
    // Cursor here shows if-specific actions
    const result = value * 2;
  }
}
