<?php

namespace App\Livewire;

use App\Http\Requests\StudentRequest;
use App\Models\Student;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Livewire\Attributes\Computed;
use Livewire\Attributes\Rule;
use Livewire\Attributes\Url;
use Livewire\Component;
use Livewire\WithPagination;

class StudentManager extends Component
{
    use WithPagination;

    // ──────────────────────────────────────────────
    // Search & UI state
    // ──────────────────────────────────────────────

    #[Url(history: true)]
    public string $search = '';

    public bool $showForm = false;

    public string $successMessage = '';

    // ──────────────────────────────────────────────
    // Form fields (validated via StudentRequest rules)
    // ──────────────────────────────────────────────

    public string $name              = '';
    public string $email             = '';
    public string $dob               = '';
    public string $address           = '';
    public string $enrollment_status = 'active';

    // ──────────────────────────────────────────────
    // Lifecycle
    // ──────────────────────────────────────────────

    /**
     * Reset pagination when search changes.
     */
    public function updatedSearch(): void
    {
        $this->resetPage();
    }

    // ──────────────────────────────────────────────
    // Computed properties
    // ──────────────────────────────────────────────

    #[Computed]
    public function students(): LengthAwarePaginator
    {
        return Student::query()
            ->when(
                $this->search,
                fn ($q) => $q->where('name', 'like', '%' . $this->search . '%')
            )
            ->orderByDesc('created_at')
            ->paginate(10);
    }

    // ──────────────────────────────────────────────
    // Actions
    // ──────────────────────────────────────────────

    /**
     * Show / hide the registration form.
     */
    public function toggleForm(): void
    {
        $this->showForm = ! $this->showForm;

        if (! $this->showForm) {
            $this->resetForm();
        }
    }

    /**
     * Save a new student using StudentRequest validation rules.
     */
    public function save(): void
    {
        // Pull the rules directly from the Form Request — single source of truth.
        $request = new StudentRequest();

        $validated = $this->validate($request->rules(), $request->messages(), $request->attributes());

        Student::create($validated);

        $this->resetForm();
        $this->showForm      = false;
        $this->successMessage = 'Student registered successfully!';

        // Auto-dismiss flash after 4 seconds via Livewire JS event
        $this->dispatch('flash-shown');
    }

    /**
     * Dismiss the flash message manually.
     */
    public function dismissFlash(): void
    {
        $this->successMessage = '';
    }

    // ──────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────

    private function resetForm(): void
    {
        $this->name              = '';
        $this->email             = '';
        $this->dob               = '';
        $this->address           = '';
        $this->enrollment_status = 'active';
        $this->resetValidation();
    }

    // ──────────────────────────────────────────────
    // Render
    // ──────────────────────────────────────────────

    public function render()
    {
        return view('livewire.student-manager')
            ->layout('layouts.app');
    }
}
