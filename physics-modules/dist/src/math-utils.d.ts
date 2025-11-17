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
export declare class VectorMath {
    static add(a: Vector3, b: Vector3): Vector3;
    static subtract(a: Vector3, b: Vector3): Vector3;
    static scale(v: Vector3, s: number): Vector3;
    static dot(a: Vector3, b: Vector3): number;
    static cross(a: Vector3, b: Vector3): Vector3;
    static magnitude(v: Vector3): number;
    static magnitudeSquared(v: Vector3): number;
    static normalize(v: Vector3): Vector3;
    static distance(a: Vector3, b: Vector3): number;
    static distanceSquared(a: Vector3, b: Vector3): number;
    static zero(): Vector3;
    static clone(v: Vector3): Vector3;
    static equals(a: Vector3, b: Vector3, epsilon?: number): boolean;
}
export declare class QuaternionMath {
    static identity(): Quaternion;
    static multiply(a: Quaternion, b: Quaternion): Quaternion;
    static conjugate(q: Quaternion): Quaternion;
    static normalize(q: Quaternion): Quaternion;
    static rotateVector(v: Vector3, q: Quaternion): Vector3;
    static clone(q: Quaternion): Quaternion;
}
export declare const RAD_TO_DEG: number;
export declare const DEG_TO_RAD: number;
export declare const G = 6.6743e-11;
//# sourceMappingURL=math-utils.d.ts.map