import coremltools
import argparse
import configparser
import io
import os

parser = argparse.ArgumentParser(description='Darknet To Keras Converter.')
parser.add_argument('input_path', help='Path to input Keras h5 model file.')
parser.add_argument('output_path', help='Path to output CoreML model file.')
    
def _main(args):
    input_path = os.path.expanduser(args.input_path)
    output_path = os.path.expanduser(args.output_path)
    assert input_path.endswith('.h5'), 'input path {} is not a .h5 file'.format(input_path)
    assert output_path.endswith('.mlmodel'), 'output path {} is not a .mlmodel file'.format(output_path)
    
    coreml_model = coremltools.converters.keras.convert(input_path, input_names='input1', image_input_names='input1', output_names=['output1', 'output2', 'output3'], image_scale=1/255.)
    
    coreml_model.input_description['input1'] = 'Input image'
    coreml_model.output_description['output1'] = 'The 13x13 grid (Scale1)'
    coreml_model.output_description['output2'] = 'The 26x26 grid (Scale2)'
    coreml_model.output_description['output3'] = 'The 52x52 grid (Scale3)'
    
    coreml_model.author = 'Original paper: Joseph Redmon, Ali Farhadi'
    coreml_model.license = 'Public Domain'
    coreml_model.short_description = "The YOLOv3 network from the paper 'YOLOv3: An Incremental Improvement'"
    
    coreml_model.save(output_path)

if __name__ == '__main__':
    _main(parser.parse_args())

