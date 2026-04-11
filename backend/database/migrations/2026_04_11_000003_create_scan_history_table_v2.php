<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration
{
    public function up(): void
    {
        Schema::createIfNotExists('scan_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('item_name');
            $table->string('category');
            $table->string('emoji');
            $table->integer('confidence');
            $table->integer('points_earned')->default(10);
            $table->timestamps();
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('scan_history');
    }
};