<?php

/*
|--------------------------------------------------------------------------
| Application Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all of the routes for an application.
| It's a breeze. Simply tell Laravel the URIs it should respond to
| and give it the controller to call when that URI is requested.
|
*/
use App\Domain;
use Illuminate\Http\Request;

/**
* Show Domain Dashboard
*/
Route::get('/', function () {
$domains = Domain::orderBy('domain_name', 'asc')->get();

return view('domains', [
'domains' => $domains
]);
});

/**
* Add New Domain
*/
Route::post('/domain', function (Request $request) {
$validator = Validator::make($request->all(), [
'domain_name' => 'required|max:255',
'agent_email' => 'required|max:255',
'owner_email' => 'required|max:255',
'admin_email' => 'required|max:255',
'tech_email' => 'required|max:255',
'billing_email' => 'required|max:255',
]);

if ($validator->fails()) {
return redirect('/')
->withInput()
->withErrors($validator);
}

// Set datetime format
$reg_date = new DateTime();
$reg_date->format('Y-m-d H:i:s');
$exp_date = new DateTime();
$exp_date->format('Y-m-d H:i:s');
$exp_date->add(new DateInterval('P'.$request->registered_years.'Y'));


// Set domain fields
$domain = new Domain;
$domain->domain_name = $request->domain_name;
$domain->agent_email = $request->agent_email;
$domain->owner_email = $request->owner_email;
$domain->admin_email = $request->admin_email;
$domain->tech_email = $request->tech_email;
$domain->billing_email = $request->billing_email;
$domain->registered_date = $reg_date;
$domain->expiration_date = $exp_date;
$domain->save();

return redirect('/');
});

/**
* Delete Domain
*/
Route::delete('/domain/{domain}', function (Domain $domain) {
$domain->delete();

return redirect('/');
