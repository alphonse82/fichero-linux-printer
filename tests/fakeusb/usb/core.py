"""Minimal fake PyUSB: tests set DEVICES and read Device.writes, no hardware."""

DEVICES = []


class USBError(IOError):
    def __init__(self, strerror, error_code=None, errno=None):
        IOError.__init__(self, errno, strerror)
        self.backend_error_code = error_code


class NoBackendError(ValueError):
    pass


class Endpoint:
    bmAttributes = 2

    def __init__(self, device, address):
        self.device, self.bEndpointAddress = device, address

    def write(self, data, timeout=None):
        return self.device.write(self.bEndpointAddress, data, timeout)


class Interface:
    bInterfaceClass, bInterfaceSubClass, bInterfaceProtocol = 7, 1, 2
    bAlternateSetting = bInterfaceNumber = 0

    def __init__(self, device):
        self.endpoints = [Endpoint(device, 0x01), Endpoint(device, 0x81)]

    def __iter__(self):
        return iter(self.endpoints)


class Device:
    def __init__(self, serial="EXAMPLE123", fail_after=None, open_error=None):
        self._serial, self.fail_after, self.open_error = serial, fail_after, open_error
        self.writes, self.claimed, self.detached, self.disposed = [], False, False, False

    @property
    def serial_number(self):
        if self._serial is None:
            raise ValueError("The device has no langid (permission issue?)")
        return self._serial

    def get_active_configuration(self):
        if self.open_error:
            raise self.open_error
        return [Interface(self)]

    def is_kernel_driver_active(self, interface):
        return True

    def detach_kernel_driver(self, interface):
        self.detached = True

    def attach_kernel_driver(self, interface):
        self.detached = False

    def write(self, endpoint, data, timeout=None):
        if self.fail_after is not None and len(self.writes) >= self.fail_after:
            raise USBError("Operation timed out", errno=110)
        self.writes.append(bytes(data))
        return len(data)


def find(find_all=False, idVendor=None, idProduct=None):
    return list(DEVICES)
