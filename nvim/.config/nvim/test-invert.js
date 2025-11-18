// Test file for condition inversion with branch swapping

function testInversion() {
  const score = 85;

  // Test 1: if-else statement (branches will be swapped)
  if (score >= 90) {
    // comment
    console.log("Excellent!");
    return "A";
  } else {
    console.log("Good job!");
    return "B";
  }
}

function testWithoutElse() {
  const value = 42;

  // Test 2: if statement without else (only condition inverted)
  if (value >= 50) {
    console.log("Less than 50");
    return true;
  }

  return false;
}

function testComplex() {
  const x = 10;
  const y = 20;

  // Test 3: complex condition with else
  if (x > 5 && y < 30) {
    console.log("Both conditions met");
    doSomething();
  } else {
    console.log("Conditions not met");
    doSomethingElse();
  }
}

function testElseIf() {
  const temp = 25;

  // Test 4: if-else if-else chain
  if (temp < 0) {
    console.log("Freezing");
  } else if (temp < 20) {
    console.log("Cold");
  } else {
    console.log("Warm");
  }
}
