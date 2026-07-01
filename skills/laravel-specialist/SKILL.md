---
name: laravel-specialist
description: Especialista en Laravel 12 y PHP 8.3+. Modelos Eloquent, migrations, API Resources, Sanctum, jobs/queues, Livewire, Pest/PHPUnit. Invocar cuando el trabajo toca Laravel directamente — modelos, rutas, controllers, servicios, tests, optimización de queries Eloquent. Activar con "/laravel" o cuando la tarea sea específica de Laravel.
user-invocable: true
---

Especialista Laravel 12 con PHP 8.3+, Eloquent ORM y PostgreSQL. Adaptado del trabajo de Jeffallan (MIT).

## Flujo de trabajo

1. **Analizar** — identificar modelos, relaciones, rutas y necesidades de queue
2. **Diseñar** — schema, service layer, jobs
3. **Implementar modelos** — `php artisan make:model -mf`; verificar con `php artisan migrate:status`
4. **Construir features** — controllers, services, API resources, jobs; verificar con `php artisan route:list`
5. **Testear** — tests de feature y unit con Pest; `php artisan test` antes de marcar como listo

## Reglas no negociables

**SIEMPRE:**
- PHP 8.3+: `readonly`, enums, typed properties, `declare(strict_types=1)`
- Type hints en todos los parámetros y return types
- Eager loading con `::with()` — nunca N+1
- API Resources para transformar datos que salen por la API
- Queues para tareas que tarden más de ~500ms
- Validación en Form Requests, nunca raw en el controller
- PSR-12 — correr `./vendor/bin/pint` antes de entregar

**NUNCA:**
- Raw queries sin protección (usar parámetros o Query Builder)
- Lógica de negocio en controllers — usar Services o Actions
- Valores de config hardcodeados — usar `config()` y `.env`
- Ignorar fallos de queue — siempre implementar `failed()`
- Features deprecadas de Laravel

## Templates de código

### Modelo Eloquent

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

final class Invoice extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['number', 'status', 'total', 'client_id'];

    protected $casts = [
        'status'     => InvoiceStatus::class,  // backed enum
        'total'      => 'decimal:2',
        'issued_at'  => 'immutable_date',
    ];

    public function client(): BelongsTo
    {
        return $this->belongsTo(Client::class);
    }

    public function lines(): HasMany
    {
        return $this->hasMany(InvoiceLine::class);
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', InvoiceStatus::Pending);
    }
}
```

### Migration (PostgreSQL)

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('client_id')->constrained()->cascadeOnDelete();
            $table->string('number')->unique();
            $table->string('status')->default('draft');
            $table->decimal('total', 12, 2)->default(0);
            $table->date('issued_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['client_id', 'status']);
            $table->index('issued_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('invoices');
    }
};
```

### API Resource

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

final class InvoiceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'number'     => $this->number,
            'status'     => $this->status->value,
            'total'      => $this->total,
            'issued_at'  => $this->issued_at?->toDateString(),
            'client'     => new ClientResource($this->whenLoaded('client')),
            'lines'      => InvoiceLineResource::collection($this->whenLoaded('lines')),
        ];
    }
}
```

### Form Request con validación

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

final class StoreInvoiceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('create', Invoice::class);
    }

    public function rules(): array
    {
        return [
            'client_id'        => ['required', 'integer', 'exists:clients,id'],
            'issued_at'        => ['required', 'date'],
            'lines'            => ['required', 'array', 'min:1'],
            'lines.*.product'  => ['required', 'string', 'max:255'],
            'lines.*.quantity' => ['required', 'integer', 'min:1'],
            'lines.*.price'    => ['required', 'numeric', 'min:0'],
        ];
    }
}
```

### Job con manejo de fallos

```php
<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Models\Invoice;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

final class SendInvoiceEmail implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries   = 3;
    public int $backoff = 60;

    public function __construct(
        private readonly Invoice $invoice,
    ) {}

    public function handle(): void
    {
        // lógica de envío
    }

    public function failed(\Throwable $e): void
    {
        logger()->error('SendInvoiceEmail failed', [
            'invoice' => $this->invoice->id,
            'error'   => $e->getMessage(),
        ]);
    }
}
```

### Feature Test (Pest)

```php
<?php

use App\Models\Invoice;
use App\Models\User;
use App\Jobs\SendInvoiceEmail;

it('creates an invoice and queues the email', function (): void {
    Queue::fake();
    $user = User::factory()->create();

    $response = $this->actingAs($user)
        ->postJson('/api/invoices', [
            'client_id' => Client::factory()->create()->id,
            'issued_at' => '2026-01-15',
            'lines'     => [['product' => 'Servicio A', 'quantity' => 1, 'price' => 500]],
        ]);

    $response->assertCreated()
             ->assertJsonPath('data.status', 'draft');

    Queue::assertPushed(SendInvoiceEmail::class);
});

it('rejects unauthenticated invoice creation', function (): void {
    $this->postJson('/api/invoices', [])->assertUnauthorized();
});
```

## Optimización de queries Eloquent

```php
// MAL — N+1: una query por cada invoice
$invoices = Invoice::all();
foreach ($invoices as $invoice) {
    echo $invoice->client->name;  // query por cada iteración
}

// BIEN — eager loading
$invoices = Invoice::with(['client', 'lines'])->pending()->get();

// Para paginación con relaciones
$invoices = Invoice::with('client')
    ->whereBetween('issued_at', [$from, $to])
    ->orderByDesc('issued_at')
    ->paginate(25);

// select() para evitar traer columnas innecesarias en listados
$invoices = Invoice::select(['id', 'number', 'status', 'total', 'issued_at', 'client_id'])
    ->with('client:id,name')
    ->paginate(25);
```

## Checkpoints de validación

| Etapa | Comando | Resultado esperado |
|-------|---------|-------------------|
| Después de migration | `php artisan migrate:status` | Todas en `Ran` |
| Después de routing | `php artisan route:list --path=api` | Rutas nuevas con verbos correctos |
| Después de job | `php artisan queue:work --once` | Job procesa sin excepción |
| Antes de entregar | `php artisan test --parallel` | 0 fallos |
| Code style | `./vendor/bin/pint --test` | Sin errores PSR-12 |
| Análisis estático | `./vendor/bin/phpstan analyse` | Nivel 5+ sin errores |
