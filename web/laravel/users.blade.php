<!-- resources/views/users.blade.php -->

@extends('layouts.app')

@section('content')

    <!-- Bootstrap Boilerplate... -->

    <div class="panel-body">
        <!-- Display Validation Errors -->
        @include('common.errors')

        <!-- New User Form -->
        <form action="{{ url('users') }}" method="POST" class="form-horizontal">
            {{ csrf_field() }}

            <!-- Username -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Username</label>

                <div class="col-sm-6">
                    <input type="text" name="username" id="username" class="form-control">
                </div>
			</div>
            <!-- Password -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Password</label>

                <div class="col-sm-6">
                    <input type="text" name="password" id="password" class="form-control">
                </div>
			</div>
            <!-- Firstname -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Firstname</label>

                <div class="col-sm-6">
                    <input type="text" name="firstname" id="firstname" class="form-control">
                </div>
			</div>
            <!-- Lastname -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Lastname</label>

                <div class="col-sm-6">
                    <input type="text" name="lastname" id="lastname" class="form-control">
                </div>
			</div>
            <!-- Organization -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Organization</label>

                <div class="col-sm-6">
                    <input type="text" name="organization" id="organization" class="form-control">
                </div>
			</div>
            <!-- Orgnr -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Organization number</label>

                <div class="col-sm-6">
                    <input type="text" name="orgnr" id="orgnr" class="form-control">
                </div>
			</div>
            <!-- User type -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">User type</label>

                <div class="col-sm-6">
                    <input type="text" name="userType" id="userType" class="form-control">
                </div>
			</div>
            <!-- Address 1 -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Address</label>

                <div class="col-sm-6">
                    <input type="text" name="address1" id="address1" class="form-control">
                </div>
			</div>
            <!-- Address 2 -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">C/O</label>

                <div class="col-sm-6">
                    <input type="text" name="address2" id="address2" class="form-control">
                </div>
			</div>
            <!-- City -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">City</label>

                <div class="col-sm-6">
                    <input type="text" name="city" id="city" class="form-control">
                </div>
			</div>
            <!-- Zip -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Zip</label>

                <div class="col-sm-6">
                    <input type="text" name="zip" id="zip" class="form-control">
                </div>
			</div>
            <!-- Country -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Country</label>

                <div class="col-sm-6">
                    <input type="text" name="country" id="country" class="form-control">
                </div>
			</div>
            <!-- Phone -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Phone</label>

                <div class="col-sm-6">
                    <input type="text" name="phone" id="phone" class="form-control">
                </div>
			</div>
            <!-- Fax -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">Fax</label>

                <div class="col-sm-6">
                    <input type="text" name="fax" id="fax" class="form-control">
                </div>
			</div>
            <!-- E-mail -->
            <div class="form-group">
                <label for="users" class="col-sm-3 control-label">E-mail</label>

                <div class="col-sm-6">
                    <input type="text" name="email" id="email" class="form-control">
                </div>
			</div>
            <!-- Add User Button -->
            <div class="form-group">
                <div class="col-sm-offset-3 col-sm-6">
                    <button type="submit" class="btn btn-default">
                        <i class="fa fa-plus"></i> Add User
                    </button>
                </div>
            </div>
        </form>
    </div>
    <!-- Current users -->
    @if (count($users) > 0)
        <div class="panel panel-default">
            <div class="panel-heading">
                Current Users
            </div>

            <div class="panel-body">
                <table class="table table-striped task-table">

                    <!-- Table Headings -->
                    <thead>
                        <th>Username</th>
                        <th>&nbsp;</th>
                    </thead>

                    <!-- Table Body -->
                    <tbody>
                        @foreach ($users as $user)
                            <tr>
                                <!-- Username -->
                                <td class="table-text">
                                    <div>{{ $user->username }}</div>
                                </td>
                                <td>
    								<!-- Delete Button -->
							        <form action="{{ url('users/'.$user->id) }}" method="POST">
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
@endsection
