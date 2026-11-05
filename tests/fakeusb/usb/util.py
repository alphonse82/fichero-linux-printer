ENDPOINT_OUT, ENDPOINT_IN = 0x00, 0x80


def endpoint_direction(address):
    return address & 0x80


def find_descriptor(descriptors, custom_match):
    return next((d for d in descriptors if custom_match(d)), None)


def claim_interface(device, interface):
    device.claimed = True


def release_interface(device, interface):
    device.claimed = False


def dispose_resources(device):
    device.disposed = True
