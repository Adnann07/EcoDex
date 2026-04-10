<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ScanHistory extends Model
{
    protected $table = 'scan_history';

    protected $fillable = [
        'user_id',
        'item_name',
        'category',
        'emoji',
        'confidence',
        'points_earned',
    ];
}