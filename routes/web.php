<?php

use App\Livewire\StudentManager;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return redirect()->route('students.index');
});

// Dashboard redirect to student manager
Route::get('/dashboard', function () {
    return redirect()->route('students.index');
})->middleware(['auth', 'verified'])->name('dashboard');

// Profile (Breeze)
Route::view('profile', 'profile')
    ->middleware(['auth'])
    ->name('profile');

// Student Management — protected by auth
Route::middleware(['auth'])->group(function () {
    Route::get('/students', StudentManager::class)->name('students.index');
});

require __DIR__.'/auth.php';
