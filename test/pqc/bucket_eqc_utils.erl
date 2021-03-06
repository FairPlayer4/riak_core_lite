%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2016 Basho Technologies, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(bucket_eqc_utils).

%% API
-export([per_test_setup/2]).


per_test_setup(DefaultBucketProps, TestFun) ->
    try
        os:cmd("rm -rf ./meta_temp"),
        riak_core_test_util:stop_pid(whereis(riak_core_ring_events)),
        riak_core_test_util:stop_pid(whereis(riak_core_ring_manager)),
        application:set_env(riak_core, claimant_tick, 4294967295),
        application:set_env(riak_core, cluster_name, "eqc_test"),
        application:set_env(riak_core, default_bucket_props, DefaultBucketProps),
        {ok, RingEvents} = riak_core_ring_events:start_link(),
        {ok, RingMgr} = riak_core_ring_manager:start_link(test),
        {ok, Claimant} = riak_core_claimant:start_link(),

        Results = TestFun(),

        riak_core_test_util:stop_pid(Claimant),
        unlink(RingMgr),
        riak_core_ring_manager:stop(),
        riak_core_test_util:stop_pid(RingEvents),
        Results
    after
        os:cmd("rm -rf ./meta_temp"),
        meck:unload()
    end.
