<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StudentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name'              => ['required', 'string', 'max:255'],
            'email'             => ['required', 'email', 'max:255', Rule::unique('students', 'email')],
            'dob'               => ['required', 'date', 'before:today'],
            'address'           => ['required', 'string', 'max:1000'],
            'enrollment_status' => ['required', Rule::in(['active', 'inactive', 'graduated', 'suspended'])],
        ];
    }

    /**
     * Get custom attribute names for validation errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'name'              => 'full name',
            'email'             => 'email address',
            'dob'               => 'date of birth',
            'address'           => 'address',
            'enrollment_status' => 'enrollment status',
        ];
    }

    /**
     * Get custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'dob.before' => 'The date of birth must be a date before today.',
        ];
    }
}
