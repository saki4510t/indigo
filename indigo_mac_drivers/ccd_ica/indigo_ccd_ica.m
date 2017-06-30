// Copyright (c) 2017 CloudMakers, s. r. o.
// All rights reserved.
//
// You can use this software under the terms of 'INDIGO Astronomy
// open-source license' (see LICENSE.md).
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS
// OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// version history
// 2.0 by Peter Polakovic <peter.polakovic@cloudmakers.eu>

/** INDIGO ICA CCD driver
 \file indigo_ccd_ica.m
 */

#define DRIVER_VERSION 0x0001
#define DRIVER_NAME "indigo_ccd_ica"

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

#include "indigo_ccd_driver.h"
#include "indigo_focuser_driver.h"

#include "indigo_ccd_ica.h"
#include "indigo_ica_ptp.h"

static struct info {
	const char *match;
	const char *name;
	int width, height;
	float pixel_size;
} info[] = {
  { "D1", "Nikon D1", 2000, 1312, 11.8 },
  { "D1H", "Nikon D1H", 2000, 1312, 11.8 },
  { "D1X", "Nikon D1X", 3008, 2000, 7.87 },
  { "D100", "Nikon D100", 3008, 2000, 7.87 },
  { "D2H", "Nikon D2H", 2464, 1632, 9.45 },
  { "D2HS", "Nikon D2Hs", 2464, 1632, 9.45 },
  { "D2X", "Nikon D2X", 4288, 2848, 5.52 },
  { "D2XS", "Nikon D2Xs", 4288, 2848, 5.52 },
  { "D200", "Nikon D200", 3872, 2592, 6.12 },
  { "D3", "Nikon D3", 4256, 2832, 8.45 },
  { "D3S", "Nikon D3s", 4256, 2832, 8.45 },
  { "D3X", "Nikon D3X", 6048, 4032, 5.95 },
	{ "D300", "Nikon D300", 4288, 2848, 5.50 },
	{ "D300S", "Nikon D300S", 4288, 2848, 5.50 },
  { "D3000", "Nikon D40X", 3872, 2592, 6.09 },
  { "D3100", "Nikon D3100", 4608, 3072, 4.94 },
  { "D3200", "Nikon D3300", 6016, 4000, 3.92 },
  { "D3300", "Nikon D3300", 6016, 4000, 3.92 },
  { "D3400", "Nikon D3400", 6000, 4000, 3.92 },
	{ "D3A", "Nikon D3A", 4256, 2832, 8.45 },
	{ "D4", "Nikon D4", 4928, 3280, 7.30 },
	{ "D4S", "Nikon D4S", 4928, 3280, 7.30 },
  { "D40", "Nikon D40", 3008, 2000, 7.87 },
  { "D40X", "Nikon D40X", 3872, 2592, 6.09 },
	{ "D5", "Nikon D5", 5568, 3712, 6.40 },
  { "D50", "Nikon D50", 3008, 2000, 7.87 },
	{ "D500", "Nikon D500", 5568, 3712, 4.23 },
	{ "D5000", "Nikon D5000", 4288, 2848, 5.50 },
	{ "D5100", "Nikon D5100", 4928, 3264, 4.78 },
	{ "D5200", "Nikon D5200", 6000, 4000, 3.92 },
	{ "D5300", "Nikon D5300", 6000, 4000, 3.92 },
	{ "D5500", "Nikon D5500", 6000, 4000, 3.92 },
  { "D5600", "Nikon D5600", 6000, 4000, 3.92 },
  { "D60", "Nikon D60", 3872, 2592, 6.09 },
	{ "D600", "Nikon D600", 6016, 4016, 5.95 },
	{ "D610", "Nikon D610", 6016, 4016, 5.95 },
	{ "D70", "Nikon D70", 3008, 2000, 7.87 },
	{ "D70s", "Nikon D70s", 3008, 2000, 7.87 },
	{ "D700", "Nikon D700", 4256, 2832, 8.45 },
	{ "D7000", "Nikon D7000", 4928, 3264, 4.78 },
	{ "D7100", "Nikon D7100", 6000, 4000, 3.92 },
	{ "D7200", "Nikon D7200", 6000, 4000, 3.92 },
	{ "D750", "Nikon D750", 6016, 4016, 3.92 },
  { "D7500", "Nikon D7500", 5568, 3712, 6.40 },
  { "D80", "Nikon D80", 3872, 2592, 6.09 },
	{ "D800", "Nikon D800", 7360, 4912, 4.88 },
	{ "D800E", "Nikon D800E", 7360, 4912, 4.88 },
	{ "D810", "Nikon D810", 7360, 4912, 4.88 },
	{ "D810A", "Nikon D810A", 7360, 4912, 4.88 },
	{ "D90", "Nikon D90", 4288, 2848, 5.50 },
  { "DF", "Nikon Df", 4928, 3264, 4.78 },
	
	{ "Canon EOS REBEL XTI", "Canon Rebel XTI", 3888, 2592, 5.7 },
	{ "Canon EOS REBEL XT", "Canon Rebel XT", 3456, 2304, 6.4 },
	{ "Canon EOS REBEL XSI", "Canon Rebel XSI", 4272, 2848, 5.19 },
	{ "Canon EOS REBEL XS", "Canon Rebel XS", 3888, 2592, 5.7 },
	{ "Canon EOS REBEL T1I", "Canon Rebel T1I", 4752, 3168, 4.69 },
	{ "Canon EOS REBEL T2I", "Canon Rebel T2I", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL T3I", "Canon Rebel T3I", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL T3", "Canon Rebel T3", 4272, 2848, 5.19 },
	{ "Canon EOS REBEL T4I", "Canon Rebel T4I", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL T5I", "Canon Rebel T5I", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL T5", "Canon Rebel T5", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL T6I", "Canon Rebel T6I", 6000, 4000, 3.71 },
	{ "Canon EOS REBEL T6S", "Canon Rebel T6S", 6000, 4000, 3.71 },
	{ "Canon EOS REBEL T6", "Canon Rebel T6", 5184, 3456, 4.3 },
	{ "Canon EOS REBEL SL1", "Canon Rebel SL1", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X2", "Canon Kiss X2", 4272, 2848, 5.19 },
	{ "Canon EOS Kiss X3", "Canon Kiss X3", 4752, 3168, 4.69 },
	{ "Canon EOS Kiss X4", "Canon Kiss X4", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X50", "Canon Kiss X50", 4272, 2848, 5.19 },
	{ "Canon EOS Kiss X5", "Canon Kiss X5", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X6I", "Canon Kiss X6I", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X7I", "Canon Kiss X7I", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X70", "Canon Kiss X70", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X7", "Canon Kiss X7", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss X8I", "Canon Kiss X8I", 6000, 4000, 3.71 },
	{ "Canon EOS Kiss X80", "Canon Kiss X80", 5184, 3456, 4.3 },
	{ "Canon EOS Kiss F", "Canon Kiss F", 3888, 2592, 5.7 },
	{ "Canon EOS 1000D", "Canon EOS 1000D", 3888, 2592, 5.7 },
	{ "Canon EOS 1100D", "Canon EOS 1100D", 4272, 2848, 5.19 },
	{ "Canon EOS 1200D", "Canon EOS 1200D", 5184, 3456, 4.3 },
	{ "Canon EOS 1300D", "Canon EOS 1300D", 5184, 3456, 4.3 },
	{ "Canon EOS 8000D", "Canon EOS 8000D", 6000, 4000, 3.71 },
	{ "Canon EOS 100D", "Canon EOS 100D", 5184, 3456, 4.3 },
	{ "Canon EOS 350D", "Canon EOS 350D", 3456, 2304, 6.4 },
	{ "Canon EOS 400D", "Canon EOS 400D", 3888, 2592, 5.7 },
	{ "Canon EOS 450D", "Canon EOS 450D", 4272, 2848, 5.19 },
	{ "Canon EOS 500D", "Canon EOS 500D", 4752, 3168, 4.69 },
	{ "Canon EOS 550D", "Canon EOS 550D", 5184, 3456, 4.3 },
	{ "Canon EOS 600D", "Canon EOS 600D", 5184, 3456, 4.3 },
	{ "Canon EOS 650D", "Canon EOS 650D", 5184, 3456, 4.3 },
	{ "Canon EOS 700D", "Canon EOS 700D", 5184, 3456, 4.3 },
	{ "Canon EOS 750D", "Canon EOS 750D", 6000, 4000, 3.71 },
	{ "Canon EOS 760D", "Canon EOS 760D", 6000, 4000, 3.71 },
	{ "Canon EOS 20D", "Canon EOS 20D", 3520, 2344, 6.4 },
	{ "Canon EOS 20DA", "Canon EOS 20DA", 3520, 2344, 6.4 },
	{ "Canon EOS 30D", "Canon EOS 30D", 3520, 2344, 6.4 },
	{ "Canon EOS 40D", "Canon EOS 40D", 3888, 2592, 5.7 },
	{ "Canon EOS 50D", "Canon EOS 50D", 4752, 3168, 4.69 },
	{ "Canon EOS 60D", "Canon EOS 60D", 5184, 3456, 4.3 },
	{ "Canon EOS 70D", "Canon EOS 70D", 5472, 3648, 6.54 },
	{ "Canon EOS 80D", "Canon EOS 80D", 6000, 4000, 3.71 },
	{ "Canon EOS 1DS MARK III", "Canon EOS 1DS", 5616, 3744, 6.41 },
	{ "Canon EOS 1D MARK III", "Canon EOS 1D", 3888, 2592, 5.7 },
	{ "Canon EOS 1D MARK IV", "Canon EOS 1D", 4896, 3264, 5.69 },
	{ "Canon EOS 1D X MARK II", "Canon EOS 1D", 5472, 3648, 6.54 },
	{ "Canon EOS 1D X", "Canon EOS 1D X", 5472, 3648, 6.54 },
	{ "Canon EOS 1D C", "Canon EOS 1D C", 5184, 3456, 4.3 },
	{ "Canon EOS 5D MARK II", "Canon EOS 5D", 5616, 3744, 6.41 },
	{ "Canon EOS 5DS", "Canon EOS 5DS", 8688, 5792, 4.14 },
	{ "Canon EOS 5D", "Canon EOS 5D", 4368, 2912, 8.2 },
	{ "Canon EOS 6D", "Canon EOS 6D", 5472, 3648, 6.54 },
	{ "Canon EOS 7D MARK II", "Canon EOS 7D", 5472, 3648, 4.07 },
	{ "Canon EOS 7D", "Canon EOS 7D", 5184, 3456, 4.3 },
	
	{ NULL, NULL, 0, 0, 0 }
};

#define DEVICE @"INDIGO_DEVICE"

#define PRIVATE_DATA        ((ica_private_data *)device->private_data)

struct dslr_properties {
	PTPPropertyCode code;
	char *name;
	char *label;
} dslr_properties[] = {
	{ PTPPropertyCodeExposureProgramMode, DSLR_PROGRAM_PROPERTY_NAME, "Exposure program" },
	{ PTPPropertyCodeFNumber, DSLR_APERTURE_PROPERTY_NAME, "Aperture" },
	{ PTPPropertyCodeExposureTime, DSLR_SHUTTER_PROPERTY_NAME, "Shutter" },
	{ PTPPropertyCodeImageSize, CCD_MODE_PROPERTY_NAME, "Image size" },
	{ PTPPropertyCodeCompressionSetting, DSLR_COMPRESSION_PROPERTY_NAME, "Compression" },
	{ PTPPropertyCodeWhiteBalance, DSLR_WHITE_BALANCE_PROPERTY_NAME, "White balance" },
	{ PTPPropertyCodeExposureIndex, DSLR_ISO_PROPERTY_NAME, "ISO" },
  { PTPPropertyCodeExposureBiasCompensation, DSLR_COMPENSATION_PROPERTY_NAME, "Compensation" },
  { PTPPropertyCodeExposureMeteringMode, DSLR_EXPOSURE_METERING_PROPERTY_NAME, "Exposure metering" },
  { PTPPropertyCodeFocusMeteringMode, DSLR_FOCUS_METERING_PROPERTY_NAME, "Focus metering" },
  { PTPPropertyCodeFocusMode, DSLR_FOCUS_MODE_PROPERTY_NAME, "Focus mode" },
  { PTPPropertyCodeBatteryLevel, DSLR_BATTERY_LEVEL_PROPERTY_NAME, "Battery level" },
	{ PTPPropertyCodeFocalLength, DSLR_FOCAL_LENGTH_PROPERTY_NAME, "Focal length" },
	{ PTPPropertyCodeFlashMode, DSLR_FLASH_MODE_PROPERTY_NAME, "Flash mode" },
	{ 0, NULL, NULL }
};

typedef struct {
	void* camera;
	struct info *info;
  indigo_device *focuser;
	indigo_property **dslr_properties;
  int dslr_properties_count;
  void *buffer;
  int buffer_size;
} ica_private_data;

// -------------------------------------------------------------------------------- INDIGO CCD device implementation

static indigo_result ccd_attach(indigo_device *device) {
	assert(device != NULL);
	assert(PRIVATE_DATA != NULL);
	if (indigo_ccd_attach(device, DRIVER_VERSION) == INDIGO_OK) {
		// --------------------------------------------------------------------------------
		if (PRIVATE_DATA->info) {
			CCD_INFO_PROPERTY->hidden = false;
			CCD_INFO_WIDTH_ITEM->number.value =  PRIVATE_DATA->info->width;
			CCD_INFO_HEIGHT_ITEM->number.value = PRIVATE_DATA->info->height;
			CCD_INFO_PIXEL_SIZE_ITEM->number.value = CCD_INFO_PIXEL_WIDTH_ITEM->number.value = CCD_INFO_PIXEL_HEIGHT_ITEM->number.value = PRIVATE_DATA->info->pixel_size;
		} else {
			CCD_INFO_PROPERTY->hidden = CCD_FRAME_PROPERTY->hidden = true;
		}
		CCD_MODE_PROPERTY->hidden = CCD_BIN_PROPERTY->hidden =  CCD_FRAME_PROPERTY->hidden = true;
    CCD_IMAGE_FORMAT_PROPERTY->perm = CCD_EXPOSURE_PROPERTY->perm = CCD_ABORT_EXPOSURE_PROPERTY->perm = INDIGO_RO_PERM;
		indigo_set_switch(CCD_IMAGE_FORMAT_PROPERTY, CCD_IMAGE_FORMAT_JPEG_ITEM, true);
		// --------------------------------------------------------------------------------
		INDIGO_DRIVER_LOG(DRIVER_NAME, "%s attached", device->name);
		return indigo_ccd_enumerate_properties(device, NULL, NULL);
	}
	return INDIGO_FAILED;
}

static indigo_result ccd_enumerate_properties(indigo_device *device, indigo_client *client, indigo_property *property) {
	indigo_result result = INDIGO_OK;
	if ((result = indigo_ccd_enumerate_properties(device, client, property)) == INDIGO_OK) {
		if (IS_CONNECTED) {
			for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++)
				if (indigo_property_match(PRIVATE_DATA->dslr_properties[i], property))
					indigo_define_property(device, PRIVATE_DATA->dslr_properties[i], NULL);
		}
	}
	return result;
}

static indigo_result ccd_change_property(indigo_device *device, indigo_client *client, indigo_property *property) {
	assert(device != NULL);
	assert(DEVICE_CONTEXT != NULL);
	assert(property != NULL);
	ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
	if (indigo_property_match(CONNECTION_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CONNECTION
		indigo_property_copy_values(CONNECTION_PROPERTY, property, false);
		ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
		if (CONNECTION_CONNECTED_ITEM->sw.value) {
			[camera requestOpenSession];
		} else {
      [camera unlock];
			[camera requestCloseSession];
		}
		CONNECTION_PROPERTY->state = INDIGO_BUSY_STATE;
		indigo_update_property(device, CONNECTION_PROPERTY, NULL);
		return INDIGO_OK;
	} else if (indigo_property_match(CCD_EXPOSURE_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CCD_EXPOSURE
		if (CCD_EXPOSURE_PROPERTY->state == INDIGO_BUSY_STATE || CCD_STREAMING_PROPERTY->state == INDIGO_BUSY_STATE)
			return INDIGO_OK;
		indigo_property_copy_values(CCD_EXPOSURE_PROPERTY, property, false);
		ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
		CCD_EXPOSURE_PROPERTY->state = INDIGO_BUSY_STATE;
		indigo_update_property(device, CCD_EXPOSURE_PROPERTY, NULL);
		CCD_IMAGE_PROPERTY->state = INDIGO_BUSY_STATE;
		indigo_update_property(device, CCD_IMAGE_PROPERTY, NULL);
		[camera startCapture];
		return INDIGO_OK;
	} else if (indigo_property_match(CCD_STREAMING_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CCD_STREAMING
		if (CCD_EXPOSURE_PROPERTY->state == INDIGO_BUSY_STATE || CCD_STREAMING_PROPERTY->state == INDIGO_BUSY_STATE)
			return INDIGO_OK;
		indigo_property_copy_values(CCD_STREAMING_PROPERTY, property, false);
		if (CCD_STREAMING_COUNT_ITEM->number.value == 0) {
			CCD_STREAMING_PROPERTY->state = INDIGO_ALERT_STATE;
		} else {
			ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
			CCD_STREAMING_PROPERTY->state = INDIGO_BUSY_STATE;
			indigo_update_property(device, CCD_STREAMING_PROPERTY, NULL);
			CCD_IMAGE_PROPERTY->state = INDIGO_BUSY_STATE;
			indigo_update_property(device, CCD_IMAGE_PROPERTY, NULL);
			[camera startLiveView];
		}
		return INDIGO_OK;
	} else if (indigo_property_match(CCD_ABORT_EXPOSURE_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- CCD_ABORT_EXPOSURE
		if (CCD_EXPOSURE_PROPERTY->state == INDIGO_BUSY_STATE ) {
      [camera stopCapture];
			CCD_EXPOSURE_PROPERTY->state = INDIGO_ALERT_STATE;
			CCD_EXPOSURE_ITEM->number.value = 0;
			indigo_update_property(device, CCD_EXPOSURE_PROPERTY, NULL);
			CCD_ABORT_EXPOSURE_PROPERTY->state = INDIGO_OK_STATE;
		} else if (CCD_STREAMING_PROPERTY->state == INDIGO_BUSY_STATE) {
			ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
			[camera stopLiveView];
			CCD_STREAMING_PROPERTY->state = INDIGO_ALERT_STATE;
			CCD_STREAMING_COUNT_ITEM->number.value = 0;
			indigo_update_property(device, CCD_STREAMING_PROPERTY, NULL);
			CCD_ABORT_EXPOSURE_PROPERTY->state = INDIGO_OK_STATE;
		} else {
			CCD_ABORT_EXPOSURE_PROPERTY->state = INDIGO_ALERT_STATE;
		}
		CCD_ABORT_EXPOSURE_ITEM->sw.value = false;
		indigo_update_property(device, CCD_ABORT_EXPOSURE_PROPERTY, CCD_ABORT_EXPOSURE_PROPERTY->state == INDIGO_OK_STATE ? "Exposure canceled" : "Failed to cancel exposure");
		return INDIGO_OK;
	}
	for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++) {
		indigo_property *dslr_property = PRIVATE_DATA->dslr_properties[i];
		if (indigo_property_match(dslr_property, property)) {
			indigo_property_copy_values(dslr_property, property, false);
			PTPPropertyCode code = 0;
			for (int i = 0; dslr_properties[i].code; i++) {
				if (!strcmp(dslr_properties[i].name, property->name)) {
					code = dslr_properties[i].code;
				}
			}
			if (!code)
				code = strtol(property->name, NULL, 16);
			switch (dslr_property->type) {
				case INDIGO_SWITCH_VECTOR: {
					for (int j = 0; j < dslr_property->count; j++) {
						if (dslr_property->items[j].sw.value) {
							dslr_property->state = INDIGO_BUSY_STATE;
							indigo_update_property(device, dslr_property, NULL);
							[camera setProperty:code value:[NSString stringWithCString:dslr_property->items[j].name encoding:NSUTF8StringEncoding]];
							break;
						}
					}
					return INDIGO_OK;
				}
				case INDIGO_NUMBER_VECTOR: {
          dslr_property->state = INDIGO_BUSY_STATE;
          indigo_update_property(device, dslr_property, NULL);
          [camera setProperty:code value:[NSString stringWithFormat:@"%d", (int)dslr_property->items[0].number.value]];
					return INDIGO_OK;
				}
				default: {
          dslr_property->state = INDIGO_BUSY_STATE;
          indigo_update_property(device, dslr_property, NULL);
          [camera setProperty:code value:[NSString stringWithCString:dslr_property->items[0].text.value encoding:NSUTF8StringEncoding]];
					return INDIGO_OK;
				}
			}
		}
	}
	return indigo_ccd_change_property(device, client, property);
}

static indigo_result ccd_detach(indigo_device *device) {
	assert(device != NULL);
	if (CONNECTION_CONNECTED_ITEM->sw.value)
		indigo_device_disconnect(NULL, device->name);
	for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++)
		indigo_release_property(PRIVATE_DATA->dslr_properties[i]);
	INDIGO_DRIVER_LOG(DRIVER_NAME, "%s detached", device->name);
	return indigo_ccd_detach(device);
}

static indigo_result focuser_attach(indigo_device *device) {
  assert(device != NULL);
  assert(PRIVATE_DATA != NULL);
  if (indigo_focuser_attach(device, DRIVER_VERSION) == INDIGO_OK) {
    // --------------------------------------------------------------------------------
    FOCUSER_ABORT_MOTION_PROPERTY->hidden = true;
    FOCUSER_POSITION_PROPERTY->hidden = true;
    FOCUSER_SPEED_PROPERTY->hidden = true;
    // --------------------------------------------------------------------------------
    INDIGO_DRIVER_LOG(DRIVER_NAME, "%s attached", device->name);
    return indigo_focuser_enumerate_properties(device, NULL, NULL);
  }
  return INDIGO_FAILED;
}

static indigo_result focuser_change_property(indigo_device *device, indigo_client *client, indigo_property *property) {
  assert(device != NULL);
  assert(DEVICE_CONTEXT != NULL);
  assert(property != NULL);
  ICCameraDevice *camera = (__bridge ICCameraDevice *)(PRIVATE_DATA->camera);
  if (indigo_property_match(CONNECTION_PROPERTY, property)) {
    // -------------------------------------------------------------------------------- CONNECTION
    indigo_property_copy_values(CONNECTION_PROPERTY, property, false);
    CONNECTION_PROPERTY->state = INDIGO_OK_STATE;
	} else if (indigo_property_match(FOCUSER_STEPS_PROPERTY, property)) {
		// -------------------------------------------------------------------------------- FOCUSER_STEPS
		indigo_property_copy_values(FOCUSER_STEPS_PROPERTY, property, false);
		if (FOCUSER_DIRECTION_MOVE_INWARD_ITEM->sw.value) {
      [camera focus:(int)FOCUSER_STEPS_ITEM->number.value];
		} else if (FOCUSER_DIRECTION_MOVE_OUTWARD_ITEM->sw.value) {
      [camera focus:(int)-FOCUSER_STEPS_ITEM->number.value];
		}
		FOCUSER_STEPS_PROPERTY->state = INDIGO_BUSY_STATE;
		indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
		return INDIGO_OK;
  }
  return indigo_focuser_change_property(device, client, property);
}

static indigo_result focuser_detach(indigo_device *device) {
  assert(device != NULL);
  if (CONNECTION_CONNECTED_ITEM->sw.value)
    indigo_device_disconnect(NULL, device->name);
  INDIGO_DRIVER_LOG(DRIVER_NAME, "%s detached", device->name);
  return indigo_focuser_detach(device);
}

// -------------------------------------------------------------------------------- ICA interface

@interface ICADelegate : PTPDelegate
@end

@implementation ICADelegate

- (void)cameraAdded:(ICCameraDevice *)camera {
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "%s", [camera.name cStringUsingEncoding:NSUTF8StringEncoding]);
	static indigo_device ccd_template = {
		"", false, NULL, NULL, INDIGO_OK, INDIGO_VERSION_CURRENT,
		ccd_attach,
		ccd_enumerate_properties,
		ccd_change_property,
		NULL,
		ccd_detach
	};
	ica_private_data *private_data = malloc(sizeof(ica_private_data));
	assert(private_data);
	memset(private_data, 0, sizeof(ica_private_data));
	private_data->camera = (__bridge void *)(camera);
	indigo_device *device = malloc(sizeof(indigo_device));
	assert(device != NULL);
	memcpy(device, &ccd_template, sizeof(indigo_device));
	strcpy(device->name, [camera.name cStringUsingEncoding:NSUTF8StringEncoding]);
	for (int i = 0; info[i].match; i++) {
		if (!strcmp(info[i].match, device->name)) {
			strcpy(device->name, info[i].name);
			private_data->info = &info[i];
			break;
		}
	}
	device->private_data = private_data;
	[camera.userData setObject:[NSValue valueWithPointer:device] forKey:DEVICE];
	indigo_async((void *)(void *)indigo_attach_device, device);
}

- (void)cameraConnected:(ICCameraDevice*)camera {
  [camera requestEnableTethering];
  [camera lock];
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "%s", [camera.name cStringUsingEncoding:NSUTF8StringEncoding]);
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	if (device) {
		for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++)
			indigo_define_property(device, PRIVATE_DATA->dslr_properties[i], NULL);
		CONNECTION_PROPERTY->state = INDIGO_OK_STATE;
		indigo_ccd_change_property(device, NULL, CONNECTION_PROPERTY);
	}
}


- (int)propertyIndex:(ICCameraDevice *)camera code:(PTPPropertyCode)code type:(indigo_property_type)type {
	char name[INDIGO_NAME_SIZE], label[INDIGO_VALUE_SIZE], *group = "Advanced";
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	indigo_property *property;
	sprintf(name, "%04x", code);
	strncpy(label, [[PTPProperty propertyCodeName:code vendorExtension:camera.ptpDeviceInfo.vendorExtension] cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_NAME_SIZE);
	for (int i = 0; i < dslr_properties[i].code; i++) {
		if (code == dslr_properties[i].code) {
			strcpy(name, dslr_properties[i].name);
			strcpy(label, dslr_properties[i].label);
			group = "DSLR";
		}
	}
	for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++) {
		property = PRIVATE_DATA->dslr_properties[i];
		if (!strcmp(name, property->name)) {
			return i;
		}
	}
	if (PRIVATE_DATA->dslr_properties)
		PRIVATE_DATA->dslr_properties = realloc(PRIVATE_DATA->dslr_properties, ++PRIVATE_DATA->dslr_properties_count * sizeof(indigo_property *));
	else
		PRIVATE_DATA->dslr_properties = malloc((PRIVATE_DATA->dslr_properties_count = 1) * sizeof(indigo_property *));
	switch (type) {
		case INDIGO_SWITCH_VECTOR: {
			property = indigo_init_switch_property(NULL, device->name, name, group, label, INDIGO_IDLE_STATE, INDIGO_RO_PERM, INDIGO_ONE_OF_MANY_RULE, 0);
			break;
		}
		case INDIGO_NUMBER_VECTOR: {
			property = indigo_init_number_property(NULL, device->name, name, group, label, INDIGO_IDLE_STATE, INDIGO_RO_PERM, 1);
			indigo_init_number_item(property->items, "VALUE", "Value", 0, 65535, 1, 0);
			break;
		}
		default: {
			property = indigo_init_text_property(NULL, device->name, name, group, label, INDIGO_IDLE_STATE, INDIGO_RO_PERM, 1);
			indigo_init_text_item(property->items, "VALUE", "Value", "");
			break;
		}
	}
	PRIVATE_DATA->dslr_properties[PRIVATE_DATA->dslr_properties_count - 1] = property;
	return PRIVATE_DATA->dslr_properties_count - 1;
}

- (void)cameraPropertyChanged:(ICCameraDevice *)camera code:(PTPPropertyCode)code value:(NSString *)value values:(NSArray<NSString *> *)values labels:(NSArray<NSString *> *)labels readOnly:(BOOL)readOnly {
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
 
	int index = [self propertyIndex:camera code:code type:INDIGO_SWITCH_VECTOR];
  indigo_property *property = PRIVATE_DATA->dslr_properties[index];
  bool redefine = (property->perm != (readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM));
	redefine = redefine || (property->count != (int)values.count);
	if (!redefine) {
		int index = 0;
		for (NSString *key in values) {
			char name[INDIGO_NAME_SIZE];
			strncpy(name, [key cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_NAME_SIZE);
			if (strcmp(property->items[index].name, name)) {
				redefine = true;
				break;
			}
			index++;
		}
	}
	switch (code) {
		case PTPPropertyCodeExposureTime: {
			int intValue = value.intValue;
			if (IS_CONNECTED)
				indigo_delete_property(device, CCD_EXPOSURE_PROPERTY, NULL);
			if (intValue != 0x7FFFFFFF) {
				CCD_EXPOSURE_ITEM->number.value = CCD_EXPOSURE_ITEM->number.min = CCD_EXPOSURE_ITEM->number.max = intValue / 10000.0;
			} else {
				CCD_EXPOSURE_ITEM->number.min = 0;
				CCD_EXPOSURE_ITEM->number.max = 10000;
			}
			if (IS_CONNECTED)
				indigo_define_property(device, CCD_EXPOSURE_PROPERTY, NULL);
			break;
		}
		case PTPPropertyCodeCompressionSetting: {
			if (value.intValue >= 4 && value.intValue <= 8) {
				if (CCD_IMAGE_FORMAT_JPEG_ITEM->sw.value) {
					indigo_set_switch(CCD_IMAGE_FORMAT_PROPERTY, CCD_IMAGE_FORMAT_RAW_ITEM, true);
					indigo_update_property(device, CCD_IMAGE_FORMAT_PROPERTY, NULL);
				}
			} else {
				if (CCD_IMAGE_FORMAT_RAW_ITEM->sw.value) {
					indigo_set_switch(CCD_IMAGE_FORMAT_PROPERTY, CCD_IMAGE_FORMAT_JPEG_ITEM, true);
					indigo_update_property(device, CCD_IMAGE_FORMAT_PROPERTY, NULL);
				}
			}
			break;
		}
	}
	property->hidden = false;
	if (redefine) {
		if (IS_CONNECTED)
			indigo_delete_property(device, property, NULL);
		PRIVATE_DATA->dslr_properties[index] = property = indigo_resize_property(property, (int)values.count);
		property->perm = readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM;
		int i = 0;
		for (NSString *key in values) {
			char name[INDIGO_NAME_SIZE];
			char label[INDIGO_VALUE_SIZE];
			strncpy(name, [key cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_NAME_SIZE);
			strncpy(label, [labels[i] cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_VALUE_SIZE);
			indigo_init_switch_item(property->items + i, name, label, [key isEqual:value]);
			i++;
		}
		if (IS_CONNECTED)
			indigo_define_property(device, property, NULL);
	} else {
		int i = 0;
		for (NSObject *object in values)
			property->items[i++].sw.value = [object isEqual:value];
		property->state = INDIGO_OK_STATE;
		indigo_update_property(device, property, NULL);
	}
}

- (void)cameraPropertyChanged:(ICCameraDevice *)camera code:(PTPPropertyCode)code value:(NSNumber *)value min:(NSNumber *)min max:(NSNumber *)max step:(NSNumber *)step readOnly:(BOOL)readOnly {
  indigo_device *device = [camera.userData[DEVICE] pointerValue];
	int index = [self propertyIndex:camera code:code type:INDIGO_NUMBER_VECTOR];
	indigo_property *property = PRIVATE_DATA->dslr_properties[index];
	bool redefine = (property->perm != (readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM));
	redefine = redefine || (property->items[0].number.min != min.intValue);
	redefine = redefine || (property->items[0].number.max != max.intValue);
	redefine = redefine || (property->items[0].number.step != step.intValue);
	property->hidden = false;
	if (redefine) {
		if (IS_CONNECTED)
			indigo_delete_property(device, property, NULL);
		property->perm = readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM;
		property->items[0].number.min = min.intValue;
		property->items[0].number.max = max.intValue;
		property->items[0].number.step = step.intValue;
		property->items[0].number.value = value.intValue;
		if (IS_CONNECTED)
			indigo_define_property(device, property, NULL);
	} else {
		property->items[0].number.value = value.intValue;
    property->state = INDIGO_OK_STATE;
		indigo_update_property(device, property, NULL);
	}
}

- (void)cameraPropertyChanged:(ICCameraDevice *)camera code:(PTPPropertyCode)code value:(NSString *)value readOnly:(BOOL)readOnly {
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	int index = [self propertyIndex:camera code:code type:INDIGO_TEXT_VECTOR];
	indigo_property *property = PRIVATE_DATA->dslr_properties[index];
	bool redefine = (property->perm != (readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM));
	property->hidden = false;
	if (redefine) {
		if (IS_CONNECTED)
			indigo_delete_property(device, property, NULL);
		property->perm = readOnly ? INDIGO_RO_PERM : INDIGO_RW_PERM;
		strncpy(property->items[0].text.value, [value cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_VALUE_SIZE);
		if (IS_CONNECTED)
			indigo_define_property(device, property, NULL);
	} else {
		strncpy(property->items[0].text.value, [value cStringUsingEncoding:NSASCIIStringEncoding], INDIGO_VALUE_SIZE);
    property->state = INDIGO_OK_STATE;
		indigo_update_property(device, property, NULL);
	}
}

- (void)cameraExposureDone:(ICCameraDevice*)camera data:(NSData *)data filename:(NSString *)filename {
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	filename = filename.lowercaseString;
	NSString *extension = [@"." stringByAppendingString:filename.pathExtension];
	if ([extension isEqualToString:@".jpg"])
		extension = @".jpeg";
	bool is_jpeg = [extension isEqualToString:@".jpeg"];
  int length = (int)data.length;
  if (PRIVATE_DATA->buffer == NULL)
    PRIVATE_DATA->buffer = malloc(length);
  else if (PRIVATE_DATA->buffer_size < length)
    PRIVATE_DATA->buffer = realloc(PRIVATE_DATA->buffer, length);
  memcpy(PRIVATE_DATA->buffer, data.bytes, length);
	if ((CCD_IMAGE_FORMAT_JPEG_ITEM->sw.value && is_jpeg) || (CCD_IMAGE_FORMAT_RAW_ITEM->sw.value && !is_jpeg)) {
		indigo_device *device = [camera.userData[DEVICE] pointerValue];
		indigo_process_dslr_image(device, PRIVATE_DATA->buffer, length, [extension cStringUsingEncoding:NSASCIIStringEncoding]);
		CCD_EXPOSURE_PROPERTY->state = INDIGO_OK_STATE;
		indigo_update_property(device, CCD_EXPOSURE_PROPERTY, NULL);
	}
	if (CCD_STREAMING_PROPERTY->state == INDIGO_BUSY_STATE) {
		if (CCD_STREAMING_COUNT_ITEM->number.value > 0) {
			CCD_STREAMING_COUNT_ITEM->number.value--;
			if (CCD_STREAMING_COUNT_ITEM->number.value == 0) {
				[camera stopLiveView];
				CCD_STREAMING_PROPERTY->state = INDIGO_OK_STATE;
			}
			indigo_update_property(device, CCD_STREAMING_PROPERTY, NULL);
		}
	}
}

- (void)cameraFocusDone:(ICCameraDevice *)camera {
  indigo_device *device = ((ica_private_data *)((indigo_device *)[camera.userData[DEVICE] pointerValue])->private_data)->focuser;
  FOCUSER_STEPS_PROPERTY->state = INDIGO_OK_STATE;
  indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
}

- (void)cameraFocusFailed:(ICCameraDevice *)camera {
  indigo_device *device = ((ica_private_data *)((indigo_device *)[camera.userData[DEVICE] pointerValue])->private_data)->focuser;
  FOCUSER_STEPS_PROPERTY->state = INDIGO_ALERT_STATE;
  indigo_update_property(device, FOCUSER_STEPS_PROPERTY, NULL);
}

- (void)cameraExposureFailed:(ICCameraDevice*)camera {
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	CCD_IMAGE_PROPERTY->state = INDIGO_ALERT_STATE;
	indigo_update_property(device, CCD_IMAGE_PROPERTY, NULL);
	CCD_EXPOSURE_PROPERTY->state = INDIGO_ALERT_STATE;
	indigo_update_property(device, CCD_EXPOSURE_PROPERTY, "Failed to exposure");
}

- (void)cameraCanCapture:(ICCameraDevice *)camera {
  indigo_device *device = [camera.userData[DEVICE] pointerValue];
  [camera requestEnableTethering];
  CCD_EXPOSURE_PROPERTY->perm = CCD_ABORT_EXPOSURE_PROPERTY->perm = INDIGO_RW_PERM;
  indigo_update_property(device, CCD_EXPOSURE_PROPERTY, NULL);
}

- (void)cameraCanFocus:(ICCameraDevice *)camera {
  indigo_device *device = [camera.userData[DEVICE] pointerValue];
  static indigo_device focuser_template = {
    "", false, NULL, NULL, INDIGO_OK, INDIGO_VERSION_CURRENT,
    focuser_attach,
    indigo_focuser_enumerate_properties,
    focuser_change_property,
    NULL,
    focuser_detach
  };
  indigo_device *focuser = malloc(sizeof(indigo_device));
  assert(focuser != NULL);
  memcpy(focuser, &focuser_template, sizeof(indigo_device));
  strcpy(focuser->name, device->name);
  strcat(focuser->name, " (focuser)");
  focuser->private_data = PRIVATE_DATA;
	PRIVATE_DATA->focuser = focuser;
  indigo_async((void *)(void *)indigo_attach_device, focuser);
}

- (void)cameraCanStream:(ICCameraDevice *)camera {
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	CCD_STREAMING_PROPERTY->hidden = false;
}

- (void)cameraDisconnected:(ICCameraDevice*)camera {
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "%s", [camera.name cStringUsingEncoding:NSUTF8StringEncoding]);
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	if (device) {
    indigo_device *focuser = PRIVATE_DATA->focuser;
    if (focuser) {
      indigo_detach_device(focuser);
      free(focuser);
      PRIVATE_DATA->focuser = NULL;
    }
		for (int i = 0; i < PRIVATE_DATA->dslr_properties_count; i++)
			indigo_delete_property(device, PRIVATE_DATA->dslr_properties[i], NULL);
		CONNECTION_PROPERTY->state = INDIGO_OK_STATE;
		indigo_ccd_change_property(device, NULL, CONNECTION_PROPERTY);
	}
}

- (void)cameraRemoved:(ICCameraDevice *)camera {
	INDIGO_DRIVER_DEBUG(DRIVER_NAME, "%s", [camera.name cStringUsingEncoding:NSUTF8StringEncoding]);
	indigo_device *device = [camera.userData[DEVICE] pointerValue];
	if (device) {
		indigo_detach_device(device);
    if (PRIVATE_DATA->buffer)
      free(PRIVATE_DATA->buffer);
    if (PRIVATE_DATA->dslr_properties)
      free(PRIVATE_DATA->dslr_properties);
		free(PRIVATE_DATA);
		free(device);
	}
}

@end

// -------------------------------------------------------------------------------- ICA interface

indigo_result indigo_ccd_ica(indigo_driver_action action, indigo_driver_info *info) {
	static indigo_driver_action last_action = INDIGO_DRIVER_SHUTDOWN;
	static ICDeviceBrowser* deviceBrowser;
	static ICADelegate* icaDelegate;
	
	SET_DRIVER_INFO(info, "ICA Camera", __FUNCTION__, DRIVER_VERSION, last_action);
	
	if (deviceBrowser == NULL) {
		deviceBrowser = [[ICDeviceBrowser alloc] init];
		deviceBrowser.delegate = icaDelegate = [[ICADelegate alloc] init];
		deviceBrowser.browsedDeviceTypeMask = ICDeviceTypeMaskCamera | ICDeviceLocationTypeMaskLocal;
	}
	
	if (action == last_action)
		return INDIGO_OK;
	
	switch (action) {
		case INDIGO_DRIVER_INIT:
			last_action = action;
			[deviceBrowser start];
			break;
		case INDIGO_DRIVER_SHUTDOWN:
			last_action = action;
			[deviceBrowser stop];
			break;
		case INDIGO_DRIVER_INFO:
			break;
	}
	
	return INDIGO_OK;
}
