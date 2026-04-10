<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('ecodex_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registration successful',
            'token'   => $token,
            'user'    => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
            ],
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($request->only('email', 'password'))) {
            throw ValidationException::withMessages([
                'email' => ['Invalid credentials.'],
            ]);
        }

        $user  = Auth::user();
        $token = $user->createToken('ecodex_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => [
                'id'    => $user->id,
                'name'  => $user->name,
                'email' => $user->email,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'user'    => $request->user(),
        ]);
    }

    public function addPoints(Request $request)
    {
        $request->validate(['points' => 'required|integer|min:1']);

        $user = $request->user();
        $user->increment('points', $request->points);
        $user->increment('total_scans');

        return response()->json([
            'success'      => true,
            'points'       => $user->fresh()->points,
            'total_scans'  => $user->fresh()->total_scans,
        ]);
    }

    public function leaderboard()
    {
        $users = User::select('name', 'points', 'total_scans')
            ->orderByDesc('points')
            ->limit(50)
            ->get()
            ->values()
            ->map(fn($u, $i) => [
                'rank'        => $i + 1,
                'name'        => $u->name,
                'points'      => $u->points,
                'total_scans' => $u->total_scans,
            ]);

        return response()->json(['success' => true, 'leaderboard' => $users]);
    }
}