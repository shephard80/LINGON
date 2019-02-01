<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Domain_contact extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'domain_contact';

	/**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = false;
}
