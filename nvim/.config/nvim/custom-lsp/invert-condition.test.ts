import { describe, it, expect } from 'vitest';
import { invertCondition } from './ast-helpers';

describe('invertCondition', () => {
  describe('comparison operators', () => {
    it('should invert equality operators', () => {
      expect(invertCondition('a === b')).toBe('a !== b');
      expect(invertCondition('a !== b')).toBe('a === b');
      expect(invertCondition('x == y')).toBe('x != y');
      expect(invertCondition('x != y')).toBe('x == y');
    });

    it('should invert comparison operators', () => {
      expect(invertCondition('a > b')).toBe('a <= b');
      expect(invertCondition('a < b')).toBe('a >= b');
      expect(invertCondition('a >= b')).toBe('a < b');
      expect(invertCondition('a <= b')).toBe('a > b');
    });

    it('should handle complex expressions', () => {
      expect(invertCondition('value > 40')).toBe('value <= 40');
      expect(invertCondition('count < 100')).toBe('count >= 100');
      expect(invertCondition('user.age >= 18')).toBe('user.age < 18');
    });
  });

  describe('logical operators', () => {
    it('should handle negation', () => {
      expect(invertCondition('!isValid')).toBe('isValid');
      expect(invertCondition('!flag')).toBe('flag');
      expect(invertCondition('isReady')).toBe('!(isReady)');
    });

    it('should apply De Morgans law for AND', () => {
      expect(invertCondition('a && b')).toBe('!(a) || !(b)');
      expect(invertCondition('x > 0 && y < 10')).toBe('x <= 0 || y >= 10');
    });

    it('should apply De Morgans law for OR', () => {
      expect(invertCondition('a || b')).toBe('!(a) && !(b)');
      expect(invertCondition('x === 0 || y === 0')).toBe('x !== 0 && y !== 0');
    });
  });

  describe('parenthesized expressions', () => {
    it('should handle parentheses', () => {
      expect(invertCondition('(a > b)')).toBe('!(a > b)');
      expect(invertCondition('(x === y)')).toBe('!(x === y)');
    });
  });

  describe('edge cases', () => {
    it('should handle method calls', () => {
      expect(invertCondition('isArray()')).toBe('!(isArray())');
      expect(invertCondition('str.includes("test")')).toBe('!(str.includes("test"))');
    });

    it('should handle property access', () => {
      expect(invertCondition('user.isActive')).toBe('!(user.isActive)');
      expect(invertCondition('!user.isActive')).toBe('user.isActive');
    });

    it('should handle whitespace', () => {
      expect(invertCondition('  a > b  ')).toBe('a <= b');
      expect(invertCondition(' !flag ')).toBe('flag');
    });
  });
});