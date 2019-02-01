<!-- resources/views/domains.blade.php -->

@extends('layouts.app')

@section('content')

<!-- Bootstrap Boilerplate... -->

<div class="panel-body">
<!-- Display Validation Errors -->
@include('common.errors')

<!-- New Domain Form -->
<form action="{{ url('domain') }}" method="POST" class="form-horizontal">
{{ csrf_field() }}

<!-- Domain Name -->
<div class="form-group">
<label for="domain" class="col-sm-3 control-label">Domain</label>

<div class="col-sm-6">
<input type="text" name="domain_name" id="domain_name" class="form-control">
</div>
<!--            </div>//-->

<!-- Agent email -->
<!--            <div class="form-group">//-->
<label for="agent_email" class="col-sm-3 control-label">Agent email</label>
<div class="col-sm-6">
<input type="text" name="agent_email" id="agent_email" class="form-control">
</div>
<!--            </div>//-->
<!-- Owner email -->
<!--            <div class="form-group">//-->
<label for="owner_email" class="col-sm-3 control-label">Owner email</label>
<div class="col-sm-6">
<input type="text" name="owner_email" id="owner_email" class="form-control">
</div>
<!--			</div>//-->
<!-- Admin email -->
<!--            <div class="form-group">//-->
<label for="admin_email" class="col-sm-3 control-label">Admin email</label>
<div class="col-sm-6">
<input type="text" name="admin_email" id="admin_email" class="form-control">
</div>
<!--			</div>//-->
<!-- Tech email -->
<!--            <div class="form-group">//-->
<label for="tech_email" class="col-sm-3 control-label">Tech email</label>
<div class="col-sm-6">
<input type="text" name="tech_email" id="tech_email" class="form-control">
</div>
<!--			</div>//-->
<!-- Billing email -->
<!--            <div class="form-group">//-->
<label for="billing_email" class="col-sm-3 control-label">Billing email</label>
<div class="col-sm-6">
<input type="text" name="billing_email" id="billing_email" class="form-control">
</div>
<!--			</div>//-->
<!-- Registered years -->
<!--            <div class="form-group">//-->
<label for="registered_years" class="col-sm-3 control-label">Registered years</label>
<div class="col-sm-6">
<select name="registered_years" id="registered_years" class="form-control">
<option value="1">1</option>
<option value="2">2</option>
<option value="3">3</option>
<option value="4">4</option>
<option value="5">5</option>
<option value="6">6</option>
<option value="7">7</option>
<option value="8">8</option>
<option value="9">9</option>
<option value="10">10</option>
</select>
</div>
<!--			</div>//-->
<!-- Add Domain Button -->
<div class="form-group">
<div class="col-sm-offset-3 col-sm-6">
<button type="submit" class="btn btn-default">
<i class="fa fa-plus"></i> Add Domain
</button>
</div>
</div>
</form>
</div>
<!-- Current Domains -->
@if (count($domains) > 0)
<div class="panel panel-default">
<div class="panel-heading">
Current Domains
</div>

<div class="panel-body">
<table class="table table-striped task-table">

<!-- Table Headings -->
<thead>
<th>Domains</th>
<th>Agent email</th>
<th>Owner email</th>
<th>Admin email</th>
<th>Tech email</th>
<th>Billing email</th>
<th>Registered date</th>
<th>Expiration date</th>
<th>&nbsp;</th>
</thead>

<!-- Table Body -->
<tbody>
@foreach ($domains as $domain)
<tr>
<!-- Domain Name -->
<td class="table-text">
<div>{{ $domain->domain_name }}</div>
</td>
<td class="table-text">
<div>{{ $domain->agent_email }}</div>
</td>
<td class="table-text">
<div>{{ $domain->owner_email }}</div>
</td>
<td class="table-text">
<div>{{ $domain->admin_email }}</div>
</td>
<td class="table-text">
<div>{{ $domain->tech_email }}</div>
</td>
<td class="table-text">
<div>{{ $domain->billing_email }}</div>
</td>
<td class="table-text">
<div>{{ $domain->registered_date }}</div>
</td>
<td class="table-text">
<div>{{ $domain->expiration_date }}</div>
</td>
<td>
<!-- Delete Button -->
<form action="{{ url('domain/'.$domain->domain_name) }}" method="POST">
{{ csrf_field() }}
{{ method_field('DELETE') }}
<button type="submit" class="btn btn-danger">
<i class="fa fa-trash"></i> Delete
</button>
</form>
</td>
</tr>
@endforeach
</tbody>
</table>
</div>
</div>
@endif
