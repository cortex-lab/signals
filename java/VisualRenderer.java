
import java.io.File;
import java.io.FileNotFoundException;
import java.lang.reflect.Array;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.nio.ShortBuffer;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

import javax.media.opengl.GL2;
import javax.media.opengl.GL2ES2;
import javax.media.opengl.GL3ES3;
import javax.media.opengl.GLAutoDrawable;
import javax.media.opengl.GLCapabilities;
import javax.media.opengl.GLEventListener;
import javax.media.opengl.GLProfile;
import javax.media.opengl.awt.GLJPanel;
import javax.swing.JFrame;
import javax.swing.WindowConstants;

import jml.Mat;

import com.jogamp.common.nio.Buffers;

import static javax.media.opengl.GL2ES2.*;

public class VisualRenderer extends GLJPanel
{
	public static GLCapabilities getDefaultCapabilities() {
		GLCapabilities caps = new GLCapabilities(GLProfile.getDefault());
		caps.setAlphaBits(8);
		return caps;
	}

	public static void main(String[] args) throws FileNotFoundException {
		Scanner scanner = new Scanner(new File("slimshady.frag"));
		String fragsrc = scanner.useDelimiter("\\Z").next();
		scanner.close();
		scanner = new Scanner(new File("slimshady.vert"));
		String vertsrc = scanner.useDelimiter("\\Z").next();
		scanner.close();
		VisualRenderer et = new VisualRenderer(vertsrc, fragsrc);
		et.layers = new Object[][] {
				{
					true, //show
					"test1",//texture id
					new double[]{0f,0f},//pos
					new double[]{360f,180f},//size
					0f,//view angle
					new double[]{0f,0f},//tex angle
					new double[]{0f,0f},//tex offset
					false, //is periodic
					false, //is stencilled
					new double[]{0f,0f,0f,0f},//min colour
					new double[]{1f,1f,1f,1f},//max colour
					new boolean[]{false, false, false, true},//rgba mask
					new float[]{
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f,
							1f, 1f, 1f, 1f,
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f,
							0f, 0f, 0f, 0f}, //rgba
							new double[]{3d, 3d}//rgbasize
				},
				{
					false, //show
					"test2",//texture id
					new double[]{0f,0f},//pos
					new double[]{360f,180f},//size
					0f,//view angle
					new double[]{0f,0f},//tex angle
					new double[]{0f,0f},//tex offset
					false, //is periodic
					false, //is stencilled
					new double[]{0f,0f,0f,0f},//min colour
					new double[]{1f,1f,1f,1f},//max colour
					new boolean[]{false, false, false, true},//rgba mask
					new float[]{
							0f, 0f, 0f, 0.5f}, //rgba
							new double[]{1d, 1d}//rgbasize
				},
				{
					true, //show
					"test3",//texture id
					new double[]{0f,0f},//pos
					new double[]{360f,180f},//size
					0f,//view angle
					new double[]{0f,0f},//tex angle
					new double[]{0f,0f},//tex offset
					false, //is periodic
					true, //is stencilled
					new double[]{0f,0f,0f,0f},//min colour
					new double[]{1f,1f,1f,1f},//max colour
					new boolean[]{true, true, true, true},//rgba mask
					new float[]{
							1f, 0f, 0f, 0f}, //rgba
							new double[]{1d, 1d}//rgbasize
				}
		};
		JFrame f = new JFrame("ogl");
		f.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
		f.setSize(64, 100);
		f.setVisible(true);
		f.setContentPane(et);
	}


	final float[] modelVertex = {
			-1f, 0.5f, 0f,
			1f, 0.5f, 0f,
			1f, -0.5f, 0f,
			-1f, -0.5f, 0f
	};
	final float[] modelUV = {
			0f, 1f,
			1f, 1f,
			1f, 0f,
			0f, 0f
	};
	final short[] modelElemIdx = {
			2, 1, 0,
			0, 3, 2
	};

	public VisualRenderer(
			//final float[] modelVertex,
			//			final float[] modelUV,
			//final short[] modelElemIdx,
			final String vsrc, 
			final String fsrc) {
		super(getDefaultCapabilities());
		addGLEventListener(new GLEventListener() {
			@Override
			public void reshape(GLAutoDrawable drawable, int x, int y, int width,
					int height) {
				//				notifyReshape(new Event(drawable, x, y, width, height));
				drawable.getGL().glViewport(x, y, width, height);
				int pw = 360;
				int ph = 180;
				float pAR = (float)pw/ph;
				float vAR = (float)width/height;
				float[] proj = new float[] {
						(float)2.0f*Math.min(pAR/vAR, 1.0f)/pw, 0f, 0f, 0f,
						0f, (float)2.0f*Math.min(vAR/pAR, 1.0f)/ph, 0f, 0f,
						0f, 0f, 1f, 0f,
						0f, 0f, 0f, 1f
				};
				setProjection(proj);
			}

			@Override
			public void init(GLAutoDrawable drawable) {
				GL3ES3 gl = drawable.getGL().getGL3ES3();
				shader = loadShader(vsrc, fsrc, gl);
				//				notifyInit(new Event(drawable));

				// get handles to shader variables
				texSamplerLoc = gl.glGetUniformLocation(shader, "myTextureSampler");
				vertexPosLoc = gl.glGetAttribLocation(shader, "vertexPos");
				uvLoc = gl.glGetAttribLocation(shader, "vertexUV");
				modelLoc = gl.glGetUniformLocation(shader, "model");
				//posLoc = gl.glGetUniformLocation(shader, "pos");
				viewLoc = gl.glGetUniformLocation(shader, "view");
				projectionLoc = gl.glGetUniformLocation(shader, "projection");
				texAngleLoc = gl.glGetUniformLocation(shader, "texAngle");
				texSizeLoc = gl.glGetUniformLocation(shader, "texSize");
				texOffsetLoc = gl.glGetUniformLocation(shader, "texOffset");
				minColourLoc = gl.glGetUniformLocation(shader, "minColor");
				maxColourLoc = gl.glGetUniformLocation(shader, "maxColor");
				// create buffer objects
				int[] buffers = new int[3]; 
				gl.glGenBuffers(3, buffers, 0);
				uvBufferObject = buffers[0];
				posBufferObject = buffers[1];
				elemBufferObject = buffers[2];
				// load model positions into buffer
				gl.glBindBuffer(GL_ARRAY_BUFFER, posBufferObject);
				gl.glBufferData(GL_ARRAY_BUFFER, 4*modelVertex.length, 
						toFloatBuffer(modelVertex), GL_STATIC_DRAW);
				// load model texture coordinates into buffer
				gl.glBindBuffer(GL_ARRAY_BUFFER, uvBufferObject);
				gl.glBufferData(GL_ARRAY_BUFFER, 4*modelUV.length, 
						toFloatBuffer(modelUV), GL_STATIC_DRAW);
				gl.glBindBuffer(GL_ARRAY_BUFFER, 0); // unbind
				// load model triangle indices into buffer
				gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elemBufferObject);
				gl.glBufferData(GL_ELEMENT_ARRAY_BUFFER, 2*modelElemIdx.length, 
						toShortBuffer(modelElemIdx), GL_STATIC_DRAW);
				gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // unbind

				// prepare the model's vertex array object
				int[] vertexArrays = new int[1];
				//GL3ES3 gl3 = gl.getGL3ES3();
				gl.glGenVertexArrays(1, vertexArrays, 0);
				modelVertexArray = vertexArrays[0];
				gl.glBindVertexArray(modelVertexArray);
				// model vertex coordinates
				gl.glBindBuffer(GL_ARRAY_BUFFER, posBufferObject);
				gl.glEnableVertexAttribArray(vertexPosLoc);
				gl.glVertexAttribPointer(vertexPosLoc, 3, GL_FLOAT, false, 0, 0);
				// model texture coordinates
				gl.glBindBuffer(GL_ARRAY_BUFFER, uvBufferObject);
				gl.glEnableVertexAttribArray(uvLoc);
				gl.glVertexAttribPointer(uvLoc, 2, GL_FLOAT, false, 0, 0);
				// model indexing
				gl.glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elemBufferObject);

				gl.glBindVertexArray(0);
				// activate texture unit
				gl.glActiveTexture(GL_TEXTURE0);

				// rendering config
				gl.glClearColor(0f, 1f, 0f, 0f);
				//				gl.glFrontFace(GL_CCW);
				//				gl.glEnable(GL_CULL_FACE);
				//				gl.glCullFace(GL_BACK);
				gl.glEnable(GL_BLEND);
				System.out.println("init complete");
			}

			@Override
			public void dispose(GLAutoDrawable drawable) {
				System.out.println("dispose");
				//				notifyDispose(new Event(drawable));
			}

			float[] model = {
					180.0f, 0.0f, 0.0f, 0.0f, 
					0.0f, 180.0f, 0.0f, 0.0f,
					0.0f, 0.0f, 180.0f, 0.0f,
					0.0f, 0.0f, 0.0f, 1.0f
			};

			@Override
			public void display(GLAutoDrawable drawable) {
				//long t = System.nanoTime();

				//notifyDisplay(new Event(drawable));
				GL3ES3 gl = drawable.getGL().getGL3ES3();
				//System.out.println("---------- display(...) ----------");
				gl.glColorMask(true, true, true, true);
				if (clearColour != null) {
					gl.glClearColor(clearColour[0], clearColour[1], clearColour[2], clearColour[3]);
					clearColour = null;
				}
				gl.glClear(GL_COLOR_BUFFER_BIT);

				// shader and model
				gl.glUseProgram(shader);
				gl.glBindVertexArray(modelVertexArray);

				//				System.out.println("model:");
				//				printmat4(model);
				gl.glUniformMatrix4fv(modelLoc, 1, false, model, 0);
				//				System.out.println("projection:");
				//				printmat4(projection);
				gl.glUniformMatrix4fv(projectionLoc, 1, false, projection, 0);
				gl.glUniform1i(texSamplerLoc, 0);

				Object[][] lays = layers;
				synchronized (lays) {
					int nlayers = lays.length;
					for (int i = 0; i < nlayers; i++) {
						try {
							Object[] l = lays[i];
							if ((l[VISIBLE_COL] != null) && !(boolean)l[VISIBLE_COL])
								continue;
							String texname = (String)l[TEX_NAME_COL];
							Integer tex = textures.get(texname);
							
							
							if (tex == null) {
								int[] texs = new int[1];
								gl.glGenTextures(1, texs, 0);
								tex = texs[0];
								loadTexture(tex, l[RGBA_COL], (double[])l[RGBA_SIZE_COL], (boolean)l[PERIODIC_COL],
										(String)l[INTERPOLATION_COL], (String)l[BLENDING_COL], gl);
								textures.put(texname, tex);
								//System.out.println(l[RGBA_COL].getClass());
								//System.out.println(l[RGBA_COL]);
								//System.out.println(((byte[])l[RGBA_COL])[0]);
							} else if (texname.charAt(0) == '~') {
								loadTexture(tex, l[RGBA_COL], (double[])l[RGBA_SIZE_COL], (boolean)l[PERIODIC_COL],
										(String)l[INTERPOLATION_COL], (String)l[BLENDING_COL], gl);
							}
							//render model with layer as texture
							switch ((String)l[BLENDING_COL]) {
							case "src":
							case "source":
								gl.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
								break;
							case "dest":
							case "destination":
								gl.glBlendFunc(GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
								break;
							case "1-src":
							case "1-source":
								gl.glBlendFunc(GL_ONE_MINUS_SRC_ALPHA, GL_SRC_ALPHA);
								//System.out.println("1-src blending");
								break;
							case "none":
								gl.glBlendFunc(GL_ONE, GL_ZERO);
								break;
							}
							//						if () {
							////							System.out.println("<stencilling>");
							//							gl.glBlendFunc(GL_DST_ALPHA, GL_ONE_MINUS_DST_ALPHA);
							//						} else {
							////							System.out.println("<overwriting>");
							//							gl.glBlendFunc(GL_ONE, GL_ZERO);
							//						}
							//gl.glEnable(GL_BLEND);
							boolean[] cm = (boolean[])l[COLOUR_MASK_COL];
							gl.glColorMask(cm[0], cm[1], cm[2], cm[3]);

							//						System.out.print("posLoc: ");
							//gl.glUniform2fv(posLoc, 1, , 0);
							float[] pos = double2float((double[])l[POS_COL]);
							//float viewAngle = (float)((double)l[VIEW_ANGLE_COL]); // use this
							float[] view = new float[] {
									1, 0, 0, pos[0],
									0, -1, 0, pos[1],
									0, 0, 1, 0,
									0, 0, 0, 1}; // make this a translation base on view angle
							//System.out.println("view:");
							//printmat4(iden4);
							gl.glUniformMatrix4fv(viewLoc, 1, true, view, 0);
							//						System.out.print("texAngleLoc: ");
							gl.glUniform1f(texAngleLoc, ((float)(double)l[TEX_ANGLE_COL]));
							//						gl.glUniform2fv(texAngleLoc, 1, double2float((double[])l[TEX_ANGLE_COL]), 0);
							//						System.out.print("texSizeLoc: ");
							gl.glUniform2fv(texSizeLoc, 1, double2float((double[])l[SIZE_COL]), 0);
							//						System.out.print("texOffsetLoc:");
							gl.glUniform2fv(texOffsetLoc, 1, double2float((double[])l[TEX_OFFSET_COL]), 0);
							//						System.out.print("minColourLoc: ");
							gl.glUniform4fv(minColourLoc, 1, double2float((double[])l[MIN_COLOUR_COL]), 0);
							//						System.out.print("maxColourLoc: ");
							gl.glUniform4fv(maxColourLoc, 1, double2float((double[])l[MAX_COLOUR_COL]), 0);

							//						params = new byte[4];
							//						gl.glGetBooleanv(GL_COLOR_WRITEMASK, params, 0);
							//						System.out.println("cm==== " + params[0] + "," + params[1]+ "," + params[2]+ "," + params[3]);// + "," + params[1]);

							gl.glBindTexture(GL_TEXTURE_2D, tex); // bind the layer's texture
							gl.glDrawElements(GL_TRIANGLES, modelElemIdx.length, GL_UNSIGNED_SHORT, 0);
							gl.glBindTexture(GL_TEXTURE_2D, 0);
						} catch (NullPointerException nullex) {
							System.err.println(nullex.getMessage());
						}
					}
				}
				gl.glBindVertexArray(0);
				gl.glBlendFunc(GL_ONE, GL_ZERO);
				gl.glUseProgram(0);

				//long dt = System.nanoTime() - t;
				//System.out.println("rendering took " + ((double)dt)/1e6 + "ms");
			}
		});
	}


	/**
	 * 
	 */
	private static final long serialVersionUID = -1746686979021577687L;

	public void clearColour(float[] rgba) {
		clearColour = rgba;
	}

	float[] clearColour;

	public static void takenumber(short[] arr) {
		for (int i = 0; i < arr.length; i++) {
			System.out.println(arr[i]);
		}
	}

	public static void takeany(Object arr) {
		System.out.println(arr);
	}

	public static float[] double2float(double[] arr) {
		float[] farr = new float[arr.length];
		//		System.out.print("[");
		for (int i = 0; i < farr.length; i++) {
			farr[i] = (float)arr[i];
			//			if (i > 0)
			//				System.out.print(",");
			//			System.out.print(farr[i]);
		}
		//		System.out.println("]");
		return farr;
	}

	public static void printmat4(float[] arr) {
		System.out.print("[");
		for (int i = 0; i < arr.length; i++) {
			if (i%4==0 && i > 0)
				System.out.println(" ");
			else if (i > 0)
				System.out.print(", ");
			System.out.print(arr[i]);
		}
		System.out.println("]");
	}

	public static void takeit(Object[][] args) {
		//		for (int i = 0; i < args.length; i++) {
		//			for (int j = 0; j < args[i].length; j++) {
		//				System.out.println(args[i][j]);
		//				if (i == 13) {
		//					boolean[] b = (boolean[])args[i][j];
		//					for (int k = 0; k < b.length; k++) {
		//						System.out.println(b[k]);
		//					}
		//				}
		//			}
		//		}
	}

	public void setLayers(Object[][] table) {
		synchronized (layers) {
			layers = table;
		}
	}
	
	public static FloatBuffer toFloatBufferFromByte(Object arr) {
		FloatBuffer buff = Buffers.newDirectFloatBuffer(Mat.numel(arr));
		Deque<Object> s = new ArrayDeque<>();
		s.push(arr);
		while (!s.isEmpty()) {
			Object e = s.removeLast();
			if (e.getClass().isArray()) {
				int len = Array.getLength(e);
				for (int i = 0; i < len; i++) {
					s.push(Array.get(e, i));
				}
			} else {
				float fval;
				if ((byte)e < 0) {
					fval = 256 + (byte)e;
				} else
				{
					fval = (byte)e;
				}
				//System.out.println("byte="+fval);
				fval = fval/255;
				buff.put(fval);
			}
		}
		buff.rewind();
		return buff;
	}

	public static FloatBuffer toFloatBuffer(Object arr) {
		FloatBuffer buff = Buffers.newDirectFloatBuffer(Mat.numel(arr));
		Deque<Object> s = new ArrayDeque<>();
		s.push(arr);
		while (!s.isEmpty()) {
			Object e = s.removeLast();
			if (e.getClass().isArray()) {
				int len = Array.getLength(e);
				for (int i = 0; i < len; i++) {
					s.push(Array.get(e, i));
				}
			} else {
				buff.put((float)e);
			}
		}
		buff.rewind();
		return buff;
	}

	public static ShortBuffer toShortBuffer(Object arr) {
		ShortBuffer buff = Buffers.newDirectShortBuffer(Mat.numel(arr));
		Deque<Object> s = new ArrayDeque<>();
		s.push(arr);
		while (!s.isEmpty()) {
			Object e = s.removeLast();
			if (e.getClass().isArray()) {
				int len = Array.getLength(e);
				for (int i = 0; i < len; i++) {
					s.push(Array.get(e, i));
				}
			} else {
				buff.put((short)e);
			}
		}
		buff.rewind();
		return buff;
	}

	public void loadTexture(int texid, Object rgba, double[] size, boolean periodic, String interpolation, String blending, GL2ES2 gl) {
		gl.glBindTexture(GL_TEXTURE_2D, texid);
		gl.glTexImage2D(
				GL_TEXTURE_2D, 
				0, // level 
				GL_RGBA, // internal format
				(int)size[0],
				(int)size[1],
				0, // border
				GL_RGBA, // format
				GL_FLOAT, // type
				toFloatBufferFromByte(rgba)); // image pixels


		if (periodic) {
			//periodic wrapping
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		} else {
			//wrap transparent
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL2.GL_CLAMP_TO_BORDER);
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL2.GL_CLAMP_TO_BORDER);
			switch (blending) {
			case "1-src":
			case "1-source":
				//System.out.println("setting special border color");
				gl.glTexParameterfv(GL_TEXTURE_2D, GL2.GL_TEXTURE_BORDER_COLOR, new float[] {1.0f, 0.0f, 0.0f, 1.0f}, 0);
				break;
			default:
				gl.glTexParameterfv(GL_TEXTURE_2D, GL2.GL_TEXTURE_BORDER_COLOR, new float[] {0.0f, 0.0f, 0.0f, 0.0f}, 0);
				break;
			}
		}
		switch (interpolation) {
		case "linear":
			//linear filtering
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			break;
		case "nearest":
			//linear filtering
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			break;
		}
		gl.glBindTexture(GL_TEXTURE_2D, 0);
	} 

	Object[][] layers = new Object[0][14];
	Map<String, Integer> textures = new HashMap<String, Integer>();

	int shader; // shader handle
	int texSamplerLoc, vertexPosLoc, uvLoc, viewLoc, modelLoc,  
	projectionLoc, texAngleLoc, texSizeLoc, texOffsetLoc, minColourLoc,
	maxColourLoc; // shader variable handles
	int uvBufferObject, posBufferObject, elemBufferObject; // buffer handles
	int modelVertexArray;

	static final int VISIBLE_COL = 0;
	static final int TEX_NAME_COL = 1;
	static final int POS_COL =  2;
	static final int SIZE_COL =  3;
	static final int VIEW_ANGLE_COL =  4;
	static final int TEX_ANGLE_COL =  5;
	static final int TEX_OFFSET_COL =  6;
	static final int PERIODIC_COL = 7;
	static final int BLENDING_COL = 8;
	static final int MIN_COLOUR_COL = 9;
	static final int MAX_COLOUR_COL = 10;
	static final int COLOUR_MASK_COL = 11;
	static final int INTERPOLATION_COL = 12;
	static final int RGBA_COL = 13;
	static final int RGBA_SIZE_COL = 14;

	public void setProjection(float[] mat) {
		projection = mat;
	}

	float[] projection = new float[16];

	int loadShader(String vsrc, String fsrc, GL2ES2 gl) {
		int vshader = gl.glCreateShader(GL_VERTEX_SHADER);
		int fshader = gl.glCreateShader(GL_FRAGMENT_SHADER);
		gl.glShaderSource(vshader, 1, new String[] {vsrc}, null, 0);
		gl.glCompileShader(vshader);
		gl.glShaderSource(fshader, 1, new String[] {fsrc}, null, 0);
		gl.glCompileShader(fshader);
		int shaderprogram = gl.glCreateProgram();
		gl.glAttachShader(shaderprogram, vshader);
		gl.glAttachShader(shaderprogram, fshader);
		gl.glLinkProgram(shaderprogram);
		gl.glValidateProgram(shaderprogram);

		IntBuffer intBuffer = IntBuffer.allocate(1);
		gl.glGetProgramiv(shaderprogram, GL_LINK_STATUS, intBuffer);

		if (intBuffer.get(0) != 1)
		{
			//gl.glGetProgramiv(shaderprogram, GL2ES2.GL_INFO_LOG_LENGTH, intBuffer);
			System.err.println("Program link error");
			//throw new Exception("GL Program link error");
		}
		return shaderprogram;
	}
}