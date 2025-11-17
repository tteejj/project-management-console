/**
 * Shared math utilities for vector and quaternion operations
 */

export interface Vector3 {
  x: number;
  y: number;
  z: number;
}

export interface Quaternion {
  w: number;
  x: number;
  y: number;
  z: number;
}

export class VectorMath {
  static add(a: Vector3, b: Vector3): Vector3 {
    return { x: a.x + b.x, y: a.y + b.y, z: a.z + b.z };
  }

  static subtract(a: Vector3, b: Vector3): Vector3 {
    return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z };
  }

  static scale(v: Vector3, s: number): Vector3 {
    return { x: v.x * s, y: v.y * s, z: v.z * s };
  }

  static dot(a: Vector3, b: Vector3): number {
    return a.x * b.x + a.y * b.y + a.z * b.z;
  }

  static cross(a: Vector3, b: Vector3): Vector3 {
    return {
      x: a.y * b.z - a.z * b.y,
      y: a.z * b.x - a.x * b.z,
      z: a.x * b.y - a.y * b.x
    };
  }

  static magnitude(v: Vector3): number {
    return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
  }

  static magnitudeSquared(v: Vector3): number {
    return v.x * v.x + v.y * v.y + v.z * v.z;
  }

  static normalize(v: Vector3): Vector3 {
    const mag = this.magnitude(v);
    if (mag < 1e-10) return { x: 0, y: 0, z: 0 };
    return this.scale(v, 1 / mag);
  }

  static distance(a: Vector3, b: Vector3): number {
    return this.magnitude(this.subtract(b, a));
  }

  static distanceSquared(a: Vector3, b: Vector3): number {
    return this.magnitudeSquared(this.subtract(b, a));
  }

  static zero(): Vector3 {
    return { x: 0, y: 0, z: 0 };
  }

  static clone(v: Vector3): Vector3 {
    return { x: v.x, y: v.y, z: v.z };
  }

  static equals(a: Vector3, b: Vector3, epsilon: number = 1e-6): boolean {
    return (
      Math.abs(a.x - b.x) < epsilon &&
      Math.abs(a.y - b.y) < epsilon &&
      Math.abs(a.z - b.z) < epsilon
    );
  }
}

export class QuaternionMath {
  static identity(): Quaternion {
    return { w: 1, x: 0, y: 0, z: 0 };
  }

  static multiply(a: Quaternion, b: Quaternion): Quaternion {
    return {
      w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
      x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
      y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
      z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
    };
  }

  static conjugate(q: Quaternion): Quaternion {
    return { w: q.w, x: -q.x, y: -q.y, z: -q.z };
  }

  static normalize(q: Quaternion): Quaternion {
    const mag = Math.sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
    if (mag < 1e-10) return this.identity();
    return {
      w: q.w / mag,
      x: q.x / mag,
      y: q.y / mag,
      z: q.z / mag
    };
  }

  static rotateVector(v: Vector3, q: Quaternion): Vector3 {
    // v' = q * v * q^(-1)
    const vQuat = { w: 0, x: v.x, y: v.y, z: v.z };
    const qConj = this.conjugate(q);
    const temp = this.multiply(q, vQuat);
    const result = this.multiply(temp, qConj);
    return { x: result.x, y: result.y, z: result.z };
  }

  static clone(q: Quaternion): Quaternion {
    return { w: q.w, x: q.x, y: q.y, z: q.z };
  }
}

export const RAD_TO_DEG = 180 / Math.PI;
export const DEG_TO_RAD = Math.PI / 180;
export const G = 6.67430e-11; // Gravitational constant m³/(kg·s²)
