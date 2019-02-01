<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Domain_data extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'domain_data';

	public $primaryKey = 'domain_name';
	public $incrementing = false;

	/**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = false;
}
