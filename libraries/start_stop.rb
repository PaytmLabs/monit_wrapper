# Copyright © 2015 ClearStory Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/mixin/shell_out'
require 'waitutil'
require_relative 'status'

class Chef
  module MonitWrapper
    module StartStop
      include Chef::Mixin::ShellOut
      include Chef::MonitWrapper::Status

      DEFAULT_MONIT_SERVICE_HOST_PORT_TIMEOUT_SEC = 60

      def start_monit_service(
          service_name,
          host: 'localhost',
          port: nil,
          timeout_sec: DEFAULT_MONIT_SERVICE_HOST_PORT_TIMEOUT_SEC)

        # Wait for the service status to stabilize to avoid the
        # "Other action already in progress -- please try again later" error.

        get_stable_monit_service_status(service_name)

        shell_out!("monit start #{service_name}")

        # Wait for service status to stabilize once again.
        get_stable_monit_service_status(service_name)

        if host && port
          Chef::Log.info(
            "Waiting for service #{service_name} to become available on host #{host}, port #{port}")
          WaitUtil.wait_for_service(service_name, host, port, delay_sec: 1,
            timeout_sec: timeout_sec)
        end
      end

      def stop_monit_service(service_name)
        get_stable_monit_service_status(service_name)
        shell_out!("monit stop #{service_name}")
        get_stable_monit_service_status(service_name)
      end

      def restart_monit_service(
          service_name,
          host: 'localhost',
          port: nil,
          timeout_sec: DEFAULT_MONIT_SERVICE_HOST_PORT_TIMEOUT_SEC)
        get_stable_monit_service_status(service_name)
        shell_out!("monit restart #{service_name}")

        # Wait for service status to stabilize once again.
        get_stable_monit_service_status(service_name)
        if host && port
          Chef::Log.info(
            "Waiting for service #{service_name} to become available on host #{host}, port #{port}")
          WaitUtil.wait_for_service(service_name, host, port, delay_sec: 1,
            timeout_sec: timeout_sec)
        end
      end

    end
  end
end